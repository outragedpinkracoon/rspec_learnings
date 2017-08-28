require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:date) { '2017-04-10' }
        let(:expected_result) do
          JSON.generate(
            'payee' => 'Starbucks',
            'amount' => 5.75,
            'date' => '2017-04-10'
          )
        end

        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(expected_result)
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-04-10'
          expect(response_body).to eq(expected_result)
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-04-10'
          expect(status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        let(:date) { '2017-04-11' }
        let(:expected_result) do
          JSON.generate []
        end

        before do
          allow(ledger).to receive(:expenses_on)
            .with(date)
            .and_return(expected_result)
        end

        it 'returns an empty array as JSON' do
          get 'expenses/2017-04-11'
          expect(response_body).to eq(expected_result)
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-04-11'
          expect(status).to eq(200)
        end
      end
    end

    describe 'POST /expenses' do
      let(:expense) { { 'some' => 'data' } }
      before do
        allow(ledger).to receive(:record)
          .with(expense)
          .and_return(RecordResult.new(true, 417, nil))
      end

      context 'when the expense is successfully recorded' do
        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)

          expect(response_body).to include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)
          expect(status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)

          expect(response_body).to include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)

          expect(status).to eq(422)
        end
      end
    end

    private

    def app
      API.new(ledger: ledger)
    end

    def response_body
      JSON.parse(last_response.body)
    end

    def status
      last_response.status
    end
  end
end
