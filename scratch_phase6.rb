require 'fileutils'

directories = [
  'app/controllers/admin',
  'app/views/layouts',
  'app/views/admin/dashboard',
  'app/views/admin/users',
  'app/views/admin/companies',
  'app/views/admin/stock_prices',
  'app/views/admin/dividends'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# Admin Layout
files['app/views/layouts/admin.html.erb'] = <<~ERB
  <!DOCTYPE html>
  <html class="h-full bg-slate-100">
    <head>
      <title>STIIP Admin</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      <%= yield :head %>
      <link rel="manifest" href="/manifest.json">
      <link rel="icon" href="/icon.png" type="image/png">
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
      <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
      <%= javascript_importmap_tags %>
    </head>
    <body class="h-full font-sans antialiased text-slate-800 bg-slate-50 flex">
      <!-- Admin Sidebar -->
      <div class="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 bg-slate-900">
        <div class="flex-1 flex flex-col min-h-0 bg-slate-900">
          <div class="flex items-center h-16 flex-shrink-0 px-4 bg-slate-900 border-b border-slate-800">
            <div class="w-8 h-8 rounded bg-gradient-to-br from-sky-500 to-sky-600 flex items-center justify-center text-white font-bold text-xl">S</div>
            <span class="ml-2 text-white font-bold text-xl tracking-tight">Admin Console</span>
          </div>
          <div class="flex-1 flex flex-col overflow-y-auto">
            <nav class="flex-1 px-2 py-4 space-y-1">
              <a href="/admin/dashboard" class="text-slate-300 hover:bg-slate-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                Dashboard
              </a>
              <a href="/admin/users" class="text-slate-300 hover:bg-slate-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                Users
              </a>
              <a href="/admin/companies" class="text-slate-300 hover:bg-slate-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                Companies
              </a>
              <a href="/admin/stock_prices" class="text-slate-300 hover:bg-slate-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                Stock Prices
              </a>
              <a href="/admin/dividends" class="text-slate-300 hover:bg-slate-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                Dividends
              </a>
              <a href="/" class="mt-8 text-sky-400 hover:text-sky-300 group flex items-center px-2 py-2 text-sm font-medium rounded-md">
                &larr; Back to App
              </a>
            </nav>
          </div>
        </div>
      </div>

      <div class="md:pl-64 flex flex-col flex-1 w-full">
        <div class="sticky top-0 z-10 flex-shrink-0 flex h-16 bg-white border-b border-slate-200 shadow-sm">
          <div class="flex-1 px-4 flex justify-between">
            <div class="flex-1 flex"></div>
            <div class="ml-4 flex items-center md:ml-6">
              <span class="text-sm font-medium text-slate-500 mr-4"><%= current_user.email %></span>
              <%= button_to "Sign out", "/users/sign_out", method: :delete, class: "text-sm text-red-600 font-medium" %>
            </div>
          </div>
        </div>

        <main class="flex-1">
          <div class="py-6">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
              <%= render "layouts/flash" %>
              <%= yield %>
            </div>
          </div>
        </main>
      </div>
    </body>
  </html>
ERB

# Base Admin Controller
files['app/controllers/admin/application_controller.rb'] = <<~RUBY
  class Admin::ApplicationController < ApplicationController
    before_action :require_admin!
    layout 'admin'
  end
RUBY

files['app/controllers/admin/dashboard_controller.rb'] = <<~RUBY
  class Admin::DashboardController < Admin::ApplicationController
    def index
      @users_count = User.count
      @companies_count = Company.count
      @premium_users = User.premium.count
    end
  end
RUBY

files['app/controllers/admin/users_controller.rb'] = <<~RUBY
  class Admin::UsersController < Admin::ApplicationController
    def index
      @users = User.all.order(created_at: :desc)
    end
  end
RUBY

files['app/controllers/admin/companies_controller.rb'] = <<~RUBY
  class Admin::CompaniesController < Admin::ApplicationController
    def index
      @companies = Company.all.order(name: :asc)
    end
  end
RUBY

files['app/controllers/admin/stock_prices_controller.rb'] = <<~RUBY
  class Admin::StockPricesController < Admin::ApplicationController
    def index
      @recent_prices = StockPrice.includes(:company).order(date: :desc).limit(50)
    end
    
    def import
      # TODO: Implement CSV parsing and insertion
      flash[:notice] = "CSV upload functionality coming soon."
      redirect_to admin_stock_prices_path
    end
  end
RUBY

files['app/controllers/admin/dividends_controller.rb'] = <<~RUBY
  class Admin::DividendsController < Admin::ApplicationController
    def index
      @dividends = Dividend.includes(:company).order(qualification_date: :desc)
    end
  end
RUBY

# Update Routes
files['config/routes.rb'] = <<~RUBY
  Rails.application.routes.draw do
    get "up" => "rails/health#show", as: :rails_health_check

    devise_for :users

    resources :companies, param: :ticker_symbol, only: [:index, :show]
    resources :dividends, only: [:index]
    resources :news_articles, param: :slug, only: [:index, :show], path: 'news'
    resources :educational_contents, param: :slug, only: [:index, :show], path: 'learn'
    resources :watchlists
    resources :notifications, only: [:index]
    
    namespace :admin do
      get 'dashboard', to: 'dashboard#index'
      resources :users
      resources :companies
      resources :stock_prices do
        collection do
          post :import
        end
      end
      resources :dividends
    end
    
    get '/profile', to: 'profiles#edit'
    get '/search', to: 'search#index'
    get '/market', to: 'market#index'
    get '/dashboard', to: 'dashboard#index'

    root "pages#home"
  end
RUBY

# Admin Views
files['app/views/admin/dashboard/index.html.erb'] = <<~ERB
  <h1 class="text-2xl font-bold text-slate-900 mb-6">Admin Dashboard</h1>
  <div class="grid grid-cols-1 gap-5 sm:grid-cols-3">
    <div class="bg-white overflow-hidden shadow rounded-lg border border-slate-200">
      <div class="px-4 py-5 sm:p-6">
        <dt class="text-sm font-medium text-slate-500 truncate">Total Users</dt>
        <dd class="mt-1 text-3xl font-semibold text-slate-900"><%= @users_count %></dd>
      </div>
    </div>
    <div class="bg-white overflow-hidden shadow rounded-lg border border-slate-200">
      <div class="px-4 py-5 sm:p-6">
        <dt class="text-sm font-medium text-slate-500 truncate">Premium Subscribers</dt>
        <dd class="mt-1 text-3xl font-semibold text-slate-900"><%= @premium_users %></dd>
      </div>
    </div>
    <div class="bg-white overflow-hidden shadow rounded-lg border border-slate-200">
      <div class="px-4 py-5 sm:p-6">
        <dt class="text-sm font-medium text-slate-500 truncate">Listed Companies</dt>
        <dd class="mt-1 text-3xl font-semibold text-slate-900"><%= @companies_count %></dd>
      </div>
    </div>
  </div>
ERB

files['app/views/admin/users/index.html.erb'] = <<~ERB
  <h1 class="text-2xl font-bold text-slate-900 mb-6">Users Directory</h1>
  <div class="bg-white shadow overflow-hidden sm:rounded-lg border border-slate-200">
    <table class="min-w-full divide-y divide-slate-200">
      <thead class="bg-slate-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Name</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Email</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Role</th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-slate-200">
        <tr class="hover:bg-slate-50">
          <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">Admin User</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500">admin@stiip.com</td>
          <td class="px-6 py-4 whitespace-nowrap"><span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-sky-100 text-sky-800">Admin</span></td>
        </tr>
      </tbody>
    </table>
  </div>
ERB

files['app/views/admin/companies/index.html.erb'] = <<~ERB
  <h1 class="text-2xl font-bold text-slate-900 mb-6">Companies Directory</h1>
  <div class="bg-white shadow overflow-hidden sm:rounded-lg border border-slate-200 p-8 text-center text-slate-500">
    Companies management table will render here.
  </div>
ERB

files['app/views/admin/stock_prices/index.html.erb'] = <<~ERB
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold text-slate-900">Stock Prices (EOD)</h1>
    <%= form_tag import_admin_stock_prices_path, multipart: true, class: "flex items-center gap-2" do %>
      <%= file_field_tag :file, class: "text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-sky-50 file:text-sky-700 hover:file:bg-sky-100" %>
      <%= submit_tag "Upload CSV", class: "bg-sky-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-sky-700 cursor-pointer" %>
    <% end %>
  </div>
  <div class="bg-white shadow overflow-hidden sm:rounded-lg border border-slate-200 p-8 text-center text-slate-500">
    Recent prices will render here.
  </div>
ERB

files['app/views/admin/dividends/index.html.erb'] = <<~ERB
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold text-slate-900">Dividends Management</h1>
    <button class="bg-sky-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-sky-700">Add Dividend</button>
  </div>
  <div class="bg-white shadow overflow-hidden sm:rounded-lg border border-slate-200 p-8 text-center text-slate-500">
    Dividends table will render here.
  </div>
ERB

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
