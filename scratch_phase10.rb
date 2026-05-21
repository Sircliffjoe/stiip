require 'fileutils'

directories = [
  'spec/models',
  'spec/requests/api/v1'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

files['spec/models/user_spec.rb'] = <<~RUBY
  require 'rails_helper'

  RSpec.describe User, type: :model do
    describe 'validations' do
      it { should validate_presence_of(:first_name) }
      it { should validate_presence_of(:last_name) }
      it { should validate_presence_of(:email) }
    end

    describe 'associations' do
      it { should have_many(:watchlists).dependent(:destroy) }
      it { should have_many(:notifications).dependent(:destroy) }
    end

    describe '#full_name' do
      it 'combines first and last name' do
        user = User.new(first_name: 'John', last_name: 'Doe')
        expect(user.full_name).to eq('John Doe')
      end
    end
  end
RUBY

files['spec/models/company_spec.rb'] = <<~RUBY
  require 'rails_helper'

  RSpec.describe Company, type: :model do
    describe 'validations' do
      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:ticker_symbol) }
      it { should validate_uniqueness_of(:ticker_symbol) }
    end

    describe 'associations' do
      it { should belong_to(:sector) }
      it { should have_many(:stock_prices).dependent(:destroy) }
    end

    describe '#pe_ratio_explanation' do
      it 'returns undervalued message for low PE' do
        company = Company.new(pe_ratio: 8)
        expect(company.pe_ratio_explanation).to include('undervalued')
      end

      it 'returns high growth message for high PE' do
        company = Company.new(pe_ratio: 30)
        expect(company.pe_ratio_explanation).to include('priced high')
      end
    end
  end
RUBY

files['spec/requests/api/v1/companies_spec.rb'] = <<~RUBY
  require 'rails_helper'

  RSpec.describe 'Api::V1::Companies', type: :request do
    let(:headers) { { 'Authorization' => 'Bearer test_token' } }

    describe 'GET /api/v1/companies' do
      it 'returns a successful response' do
        get '/api/v1/companies', headers: headers
        expect(response).to have_http_status(:success)
      end
    end
  end
RUBY

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
