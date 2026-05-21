require 'fileutils'

# Directories to create
directories = [
  'app/controllers',
  'app/views/pages',
  'app/views/market',
  'app/views/companies',
  'app/views/dividends',
  'app/views/dashboard'
]

directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# Update Navbar for Glassmorphism
files['app/components/navbar/component.html.erb'] = <<~ERB
  <nav class="bg-white/70 backdrop-blur-lg border-b border-white/30 shadow-sm fixed w-full z-30 top-0 transition-all duration-300">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <div class="flex items-center">
          <a href="/" class="flex items-center gap-2 group">
            <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-sky-400 to-sky-600 flex items-center justify-center text-white font-bold text-xl shadow-md group-hover:shadow-sky-200 transition-all">S</div>
            <span class="text-xl font-bold text-slate-800 hidden sm:block tracking-tight">STIIP</span>
          </a>
        </div>
        
        <div class="hidden md:flex flex-1 justify-center px-4 sm:px-8 gap-6 text-sm font-medium text-slate-600">
          <a href="/market" class="hover:text-sky-600 transition-colors">Market</a>
          <a href="/companies" class="hover:text-sky-600 transition-colors">Companies</a>
          <a href="/dividends" class="hover:text-sky-600 transition-colors">Dividends</a>
        </div>
        
        <div class="flex items-center gap-4">
          <div class="hidden lg:block w-48">
            <%= render SearchBar::Component.new %>
          </div>
          
          <% if @user %>
            <div class="relative" data-controller="dropdown">
              <button data-action="dropdown#toggle" class="flex items-center gap-2 p-1 rounded-full hover:bg-slate-100/50 transition border border-transparent hover:border-slate-200">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-sky-100 to-sky-200 text-sky-700 flex items-center justify-center font-bold shadow-inner border border-white">
                  <%= @user.first_name[0] %>
                </div>
              </button>
              <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-white/90 backdrop-blur-xl rounded-xl shadow-xl py-1 border border-white/50 focus:outline-none">
                <a href="/dashboard" class="block px-4 py-2 text-sm text-slate-700 hover:bg-sky-50 hover:text-sky-700">Dashboard</a>
                <a href="/profile" class="block px-4 py-2 text-sm text-slate-700 hover:bg-sky-50 hover:text-sky-700">Settings</a>
                <div class="border-t border-slate-100 my-1"></div>
                <%= button_to "Sign out", "/users/sign_out", method: :delete, class: "block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50" %>
              </div>
            </div>
          <% else %>
            <a href="/users/sign_in" class="text-sm font-medium text-slate-600 hover:text-sky-600">Log in</a>
            <a href="/users/sign_up" class="text-sm font-medium bg-gradient-to-r from-sky-500 to-sky-600 text-white px-4 py-2 rounded-lg hover:shadow-md hover:shadow-sky-200 hover:-translate-y-0.5 transition-all">Sign up</a>
          <% end %>
        </div>
      </div>
    </div>
  </nav>
ERB

# Update routes
files['config/routes.rb'] = <<~RUBY
  Rails.application.routes.draw do
    get "up" => "rails/health#show", as: :rails_health_check

    devise_for :users

    resources :companies, param: :ticker_symbol, only: [:index, :show]
    resources :dividends, only: [:index]
    
    get '/market', to: 'market#index'
    get '/dashboard', to: 'dashboard#index'

    root "pages#home"
  end
RUBY

# Controllers
files['app/controllers/pages_controller.rb'] = <<~RUBY
  class PagesController < ApplicationController
    def home
    end
  end
RUBY

files['app/controllers/market_controller.rb'] = <<~RUBY
  class MarketController < ApplicationController
    def index
      @companies = Company.all.limit(5)
      @sectors = Sector.all
    end
  end
RUBY

files['app/controllers/companies_controller.rb'] = <<~RUBY
  class CompaniesController < ApplicationController
    def index
      @companies = Company.all
    end

    def show
      @company = Company.find_by!(ticker_symbol: params[:ticker_symbol])
    end
  end
RUBY

files['app/controllers/dividends_controller.rb'] = <<~RUBY
  class DividendsController < ApplicationController
    def index
      @dividends = Dividend.includes(:company).order(qualification_date: :asc).limit(20)
    end
  end
RUBY

files['app/controllers/dashboard_controller.rb'] = <<~RUBY
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    
    def index
      @watchlists = current_user.watchlists
    end
  end
RUBY

# Views (Glassmorphic & Light-Theme specific)
files['app/views/pages/home.html.erb'] = <<~ERB
  <div class="min-h-[80vh] flex flex-col items-center justify-center text-center py-20 px-4 relative">
    <!-- Decorative background elements -->
    <div class="absolute top-20 left-20 w-64 h-64 bg-sky-200 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob"></div>
    <div class="absolute top-40 right-20 w-72 h-72 bg-gold-200 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob animation-delay-2000"></div>

    <div class="relative z-10 space-y-8 max-w-3xl">
      <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/60 backdrop-blur-md border border-white/50 text-sm font-medium text-sky-800 shadow-sm">
        <span class="flex h-2 w-2 relative">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-sky-400 opacity-75"></span>
          <span class="relative inline-flex rounded-full h-2 w-2 bg-sky-500"></span>
        </span>
        Live Nigerian Stock Intelligence
      </div>
      
      <h1 class="text-5xl sm:text-7xl font-extrabold text-slate-900 tracking-tight leading-tight">
        Your smart companion for <span class="text-transparent bg-clip-text bg-gradient-to-r from-sky-600 to-sky-400">investing</span>
      </h1>
      
      <p class="text-lg sm:text-xl text-slate-600 font-light max-w-2xl mx-auto leading-relaxed">
        Discover listed companies, track dividend opportunities, and understand market trends in plain English. No jargon.
      </p>

      <div class="flex flex-col sm:flex-row gap-4 justify-center pt-4">
        <a href="/users/sign_up" class="px-8 py-4 bg-gradient-to-r from-sky-600 to-sky-500 text-white font-semibold rounded-xl shadow-lg shadow-sky-200 hover:-translate-y-1 hover:shadow-xl hover:shadow-sky-200 transition-all">
          Get Started Free
        </a>
        <a href="/market" class="px-8 py-4 bg-white/70 backdrop-blur-md border border-white/60 text-slate-700 font-semibold rounded-xl shadow-sm hover:bg-white hover:shadow-md transition-all">
          Explore Market
        </a>
      </div>
    </div>
  </div>

  <div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8 relative z-10">
    <div class="bg-white/60 backdrop-blur-lg border border-white/50 p-8 rounded-2xl shadow-xl shadow-slate-200/50 hover:-translate-y-1 transition-transform">
      <div class="w-12 h-12 bg-sky-100 text-sky-600 rounded-xl flex items-center justify-center mb-6 shadow-sm border border-white">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
      </div>
      <h3 class="text-xl font-bold text-slate-800 mb-2">Track Stock Prices</h3>
      <p class="text-slate-600 font-light">Monitor top gainers, losers, and most traded stocks in real-time.</p>
    </div>

    <div class="bg-white/60 backdrop-blur-lg border border-white/50 p-8 rounded-2xl shadow-xl shadow-slate-200/50 hover:-translate-y-1 transition-transform">
      <div class="w-12 h-12 bg-gold-100 text-gold-600 rounded-xl flex items-center justify-center mb-6 shadow-sm border border-white">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
      </div>
      <h3 class="text-xl font-bold text-slate-800 mb-2">Dividend Calendar</h3>
      <p class="text-slate-600 font-light">Never miss a payout. Track upcoming dividends and qualification dates.</p>
    </div>

    <div class="bg-white/60 backdrop-blur-lg border border-white/50 p-8 rounded-2xl shadow-xl shadow-slate-200/50 hover:-translate-y-1 transition-transform">
      <div class="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-xl flex items-center justify-center mb-6 shadow-sm border border-white">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path></svg>
      </div>
      <h3 class="text-xl font-bold text-slate-800 mb-2">Plain English</h3>
      <p class="text-slate-600 font-light">We translate complex financial jargon into simple, actionable insights.</p>
    </div>
  </div>
ERB

files['app/views/market/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-3xl font-bold text-slate-900 tracking-tight">Market Overview</h1>
      <span class="text-sm text-slate-500 bg-white/50 backdrop-blur-sm px-3 py-1 rounded-full border border-slate-200">Last updated: Today, 2:30 PM WAT</span>
    </div>

    <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
      <div class="bg-white/70 backdrop-blur-xl border border-white/60 p-6 rounded-2xl shadow-xl shadow-slate-200/40 relative overflow-hidden">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-sky-100 rounded-full mix-blend-multiply opacity-50"></div>
        <p class="text-sm font-medium text-slate-500 relative z-10">All-Share Index (ASI)</p>
        <p class="mt-2 text-3xl font-bold text-slate-900 relative z-10">98,245.10</p>
        <div class="mt-2 text-sm text-green-600 font-medium relative z-10">+1.24%</div>
      </div>
      
      <div class="bg-white/70 backdrop-blur-xl border border-white/60 p-6 rounded-2xl shadow-xl shadow-slate-200/40 relative overflow-hidden">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-green-100 rounded-full mix-blend-multiply opacity-50"></div>
        <p class="text-sm font-medium text-slate-500 relative z-10">Market Cap (Trillion NGN)</p>
        <p class="mt-2 text-3xl font-bold text-slate-900 relative z-10">54.32</p>
        <div class="mt-2 text-sm text-green-600 font-medium relative z-10">+0.85%</div>
      </div>
      
      <div class="bg-white/70 backdrop-blur-xl border border-white/60 p-6 rounded-2xl shadow-xl shadow-slate-200/40 relative overflow-hidden">
        <div class="absolute -right-4 -top-4 w-24 h-24 bg-gold-100 rounded-full mix-blend-multiply opacity-50"></div>
        <p class="text-sm font-medium text-slate-500 relative z-10">Volume Traded (Million)</p>
        <p class="mt-2 text-3xl font-bold text-slate-900 relative z-10">452.1</p>
        <div class="mt-2 text-sm text-slate-500 font-medium relative z-10">Average</div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
      <div class="bg-white/60 backdrop-blur-md rounded-2xl border border-white/50 shadow-lg p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-4">Top Gainers</h2>
        <div class="space-y-4">
          <!-- Placeholder data for now -->
          <div class="flex justify-between items-center p-3 bg-white/50 rounded-xl border border-slate-100">
            <div>
              <p class="font-bold text-slate-900">UBA</p>
              <p class="text-xs text-slate-500">United Bank for Africa</p>
            </div>
            <div class="text-right">
              <p class="font-semibold text-slate-900">₦26.40</p>
              <p class="text-sm text-green-600">+9.8%</p>
            </div>
          </div>
          <div class="flex justify-between items-center p-3 bg-white/50 rounded-xl border border-slate-100">
            <div>
              <p class="font-bold text-slate-900">TRANSCORP</p>
              <p class="text-xs text-slate-500">Transnational Corporation</p>
            </div>
            <div class="text-right">
              <p class="font-semibold text-slate-900">₦14.20</p>
              <p class="text-sm text-green-600">+8.5%</p>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white/60 backdrop-blur-md rounded-2xl border border-white/50 shadow-lg p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-4">Market News</h2>
        <div class="space-y-4">
          <div class="p-3 bg-white/50 rounded-xl border border-slate-100 hover:bg-white cursor-pointer transition-colors">
            <p class="text-xs font-medium text-sky-600 mb-1">Earnings</p>
            <p class="font-semibold text-slate-800">GTCO Releases Q3 2026 Financial Results, Declares Interim Dividend</p>
            <p class="text-xs text-slate-500 mt-2">2 hours ago</p>
          </div>
          <div class="p-3 bg-white/50 rounded-xl border border-slate-100 hover:bg-white cursor-pointer transition-colors">
            <p class="text-xs font-medium text-gold-600 mb-1">Economy</p>
            <p class="font-semibold text-slate-800">CBN Maintains MPR at 24.75% to Curb Inflation</p>
            <p class="text-xs text-slate-500 mt-2">5 hours ago</p>
          </div>
        </div>
      </div>
    </div>
  </div>
ERB

files['app/views/companies/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <h1 class="text-3xl font-bold text-slate-900 tracking-tight">Listed Companies</h1>
      <div class="flex gap-2">
        <input type="text" placeholder="Search companies..." class="px-4 py-2 bg-white/80 backdrop-blur-sm border border-slate-200 rounded-lg shadow-sm focus:ring-sky-500 focus:border-sky-500 outline-none">
        <button class="px-4 py-2 bg-white/80 backdrop-blur-sm border border-slate-200 rounded-lg shadow-sm text-slate-700 font-medium hover:bg-white">Filter</button>
      </div>
    </div>

    <div class="bg-white/60 backdrop-blur-lg border border-white/50 rounded-2xl shadow-xl shadow-slate-200/50 overflow-hidden">
      <table class="min-w-full divide-y divide-slate-200">
        <thead class="bg-slate-50/80 backdrop-blur-sm">
          <tr>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Company</th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Sector</th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Price</th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Change</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100 bg-transparent">
          <tr class="hover:bg-white/60 transition-colors cursor-pointer">
            <td class="px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-700">MTN</div>
                <div>
                  <p class="font-bold text-slate-900">MTNN</p>
                  <p class="text-xs text-slate-500">MTN Nigeria Communications Plc</p>
                </div>
              </div>
            </td>
            <td class="px-6 py-4 text-sm text-slate-600">Telecommunications</td>
            <td class="px-6 py-4 font-semibold text-slate-900">₦240.50</td>
            <td class="px-6 py-4 text-sm text-green-600 font-medium">+1.2%</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
ERB

files['app/views/dividends/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div>
      <h1 class="text-3xl font-bold text-slate-900 tracking-tight">Dividend Calendar</h1>
      <p class="mt-2 text-slate-600 font-light max-w-2xl">Track upcoming dividend payments, qualification dates, and historical yields to maximize your passive income.</p>
    </div>

    <div class="bg-white/60 backdrop-blur-lg border border-white/50 rounded-2xl shadow-xl shadow-slate-200/50 overflow-hidden p-6">
      <h2 class="text-xl font-bold text-slate-800 mb-6">Upcoming Dividends</h2>
      
      <div class="space-y-4">
        <div class="flex flex-col sm:flex-row items-center justify-between p-4 bg-white/80 rounded-xl border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center gap-4 w-full sm:w-auto mb-4 sm:mb-0">
            <div class="w-12 h-12 rounded-full bg-gradient-to-br from-green-100 to-green-200 flex items-center justify-center text-green-700 font-bold">GT</div>
            <div>
              <p class="font-bold text-slate-900 text-lg">GTCO</p>
              <p class="text-sm text-slate-500">Guaranty Trust Holding Co.</p>
            </div>
          </div>
          
          <div class="flex flex-col sm:flex-row gap-6 sm:gap-12 w-full sm:w-auto items-start sm:items-center">
            <div>
              <p class="text-xs font-semibold text-slate-400 uppercase">Amount</p>
              <p class="font-bold text-slate-900 text-lg">₦3.20 <span class="text-xs font-normal text-slate-500">/ share</span></p>
            </div>
            <div>
              <p class="text-xs font-semibold text-slate-400 uppercase">Qualifies By</p>
              <p class="font-medium text-slate-800">Oct 15, 2026</p>
            </div>
            <div>
              <p class="text-xs font-semibold text-slate-400 uppercase">Payment Date</p>
              <p class="font-bold text-green-600">Oct 22, 2026</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
ERB

files['app/views/dashboard/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div>
      <h1 class="text-3xl font-bold text-slate-900 tracking-tight">Dashboard</h1>
      <p class="mt-1 text-slate-600">Welcome back, <%= current_user.first_name %>.</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="col-span-2 bg-white/60 backdrop-blur-lg border border-white/50 rounded-2xl shadow-xl shadow-slate-200/50 p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-4">Your Watchlists</h2>
        
        <% if @watchlists.empty? %>
          <div class="text-center py-10">
            <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
            </div>
            <p class="text-slate-600 mb-4">You aren't tracking any stocks yet.</p>
            <button class="px-4 py-2 bg-sky-600 text-white rounded-lg shadow hover:bg-sky-700">Create Watchlist</button>
          </div>
        <% else %>
          <div class="space-y-3">
            <% @watchlists.each do |list| %>
              <div class="p-4 bg-white/80 rounded-xl border border-slate-100 flex justify-between items-center">
                <span class="font-medium text-slate-800"><%= list.name %></span>
                <span class="text-sm text-slate-500"><%= list.companies.count %> companies</span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="bg-white/60 backdrop-blur-lg border border-white/50 rounded-2xl shadow-xl shadow-slate-200/50 p-6">
        <h2 class="text-xl font-bold text-slate-800 mb-4">Smart Insights</h2>
        <div class="p-4 bg-sky-50 rounded-xl border border-sky-100">
          <div class="flex items-start gap-3">
            <div class="mt-1 w-6 h-6 rounded-full bg-sky-200 flex items-center justify-center text-sky-600">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            </div>
            <div>
              <p class="font-semibold text-sky-900">High Yield Alert</p>
              <p class="text-sm text-sky-800 mt-1">Zenith Bank's current price brings its dividend yield to 12.5%, significantly above the sector average.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
ERB

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
