require 'fileutils'

directories = [
  'app/views/news_articles',
  'app/views/educational_contents',
  'app/views/watchlists',
  'app/views/notifications',
  'app/views/profiles',
  'app/views/search'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# Controllers
files['app/controllers/news_articles_controller.rb'] = <<~RUBY
  class NewsArticlesController < ApplicationController
    def index
      @articles = NewsArticle.all.order(published_at: :desc)
    end
    def show
      @article = NewsArticle.find_by!(slug: params[:slug])
    end
  end
RUBY

files['app/controllers/educational_contents_controller.rb'] = <<~RUBY
  class EducationalContentsController < ApplicationController
    def index
      @contents = EducationalContent.all.order(published_at: :desc)
    end
    def show
      @content = EducationalContent.find_by!(slug: params[:slug])
    end
  end
RUBY

files['app/controllers/watchlists_controller.rb'] = <<~RUBY
  class WatchlistsController < ApplicationController
    before_action :authenticate_user!
    def index
      @watchlists = current_user.watchlists
    end
    def show
      @watchlist = current_user.watchlists.find(params[:id])
    end
  end
RUBY

files['app/controllers/notifications_controller.rb'] = <<~RUBY
  class NotificationsController < ApplicationController
    before_action :authenticate_user!
    def index
      @notifications = current_user.notifications.order(created_at: :desc)
    end
  end
RUBY

files['app/controllers/profiles_controller.rb'] = <<~RUBY
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    def edit
      @user = current_user
    end
  end
RUBY

files['app/controllers/search_controller.rb'] = <<~RUBY
  class SearchController < ApplicationController
    def index
      @query = params[:query]
    end
  end
RUBY

# Routes update
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
    
    get '/profile', to: 'profiles#edit'
    get '/search', to: 'search#index'
    get '/market', to: 'market#index'
    get '/dashboard', to: 'dashboard#index'

    root "pages#home"
  end
RUBY

# Views
files['app/views/companies/show.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div class="flex items-center gap-4">
      <a href="/companies" class="text-sky-600 hover:text-sky-800 transition flex items-center gap-1 text-sm font-medium">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
        Back
      </a>
    </div>

    <div class="bg-white/60 backdrop-blur-xl border border-white/60 rounded-2xl shadow-xl shadow-slate-200/40 p-8">
      <div class="flex flex-col md:flex-row justify-between gap-6">
        <div class="flex items-center gap-6">
          <div class="w-20 h-20 rounded-2xl bg-white border border-slate-100 shadow-sm flex items-center justify-center font-bold text-slate-800 text-2xl">
            <%= @company.ticker_symbol[0..1] %>
          </div>
          <div>
            <h1 class="text-3xl font-bold text-slate-900"><%= @company.name %></h1>
            <div class="flex items-center gap-3 mt-2 text-sm text-slate-500">
              <span class="px-2 py-1 bg-slate-100 rounded-md font-medium"><%= @company.ticker_symbol %></span>
              <span>•</span>
              <span><%= @company.sector&.name || 'Unknown Sector' %></span>
            </div>
          </div>
        </div>

        <div class="flex flex-col md:items-end justify-center">
          <p class="text-3xl font-bold text-slate-900">₦<%= @company.latest_price || '0.00' %></p>
          <p class="text-sm text-green-600 font-medium mt-1">+2.4% Today</p>
        </div>
      </div>

      <div class="mt-8 pt-8 border-t border-slate-200/50 grid grid-cols-2 md:grid-cols-4 gap-6">
        <div>
          <p class="text-xs font-semibold text-slate-400 uppercase">Market Cap</p>
          <p class="text-lg font-medium text-slate-900 mt-1">₦<%= @company.market_cap || 'N/A' %>B</p>
        </div>
        <div>
          <p class="text-xs font-semibold text-slate-400 uppercase">PE Ratio</p>
          <p class="text-lg font-medium text-slate-900 mt-1"><%= @company.pe_ratio || 'N/A' %></p>
        </div>
        <div>
          <p class="text-xs font-semibold text-slate-400 uppercase">Div Yield</p>
          <p class="text-lg font-medium text-slate-900 mt-1"><%= @company.dividend_yield || '0.0' %>%</p>
        </div>
        <div>
          <p class="text-xs font-semibold text-slate-400 uppercase">52 Wk High</p>
          <p class="text-lg font-medium text-slate-900 mt-1">₦<%= @company.high_52_week || 'N/A' %></p>
        </div>
      </div>
    </div>

    <!-- AI Explanation Card -->
    <div class="bg-gradient-to-br from-sky-50 to-white backdrop-blur-md border border-sky-100 rounded-2xl shadow-lg shadow-sky-100/50 p-6 flex gap-4 items-start">
      <div class="w-10 h-10 rounded-full bg-sky-200 flex items-center justify-center text-sky-700 shrink-0">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
      </div>
      <div>
        <h3 class="font-bold text-sky-900">What this means for you</h3>
        <p class="text-sm text-sky-800 mt-1"><%= @company.pe_ratio_explanation %></p>
      </div>
    </div>
  </div>
ERB

files['app/views/news_articles/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <h1 class="text-3xl font-bold text-slate-900">Market News</h1>
    <div class="bg-white/60 backdrop-blur-xl border border-white/60 rounded-2xl shadow-xl shadow-slate-200/40 p-12 text-center">
      <p class="text-slate-500">News articles will appear here.</p>
    </div>
  </div>
ERB

files['app/views/educational_contents/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <h1 class="text-3xl font-bold text-slate-900">Learn to Invest</h1>
    <div class="bg-white/60 backdrop-blur-xl border border-white/60 rounded-2xl shadow-xl shadow-slate-200/40 p-12 text-center">
      <p class="text-slate-500">Educational modules will appear here.</p>
    </div>
  </div>
ERB

files['app/views/watchlists/index.html.erb'] = <<~ERB
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-3xl font-bold text-slate-900">Watchlists</h1>
      <button class="px-4 py-2 bg-sky-600 text-white rounded-lg shadow hover:bg-sky-700">New Watchlist</button>
    </div>
    <div class="bg-white/60 backdrop-blur-xl border border-white/60 rounded-2xl shadow-xl shadow-slate-200/40 p-12 text-center">
      <p class="text-slate-500">Your watchlists will appear here.</p>
    </div>
  </div>
ERB

files['app/views/profiles/edit.html.erb'] = <<~ERB
  <div class="space-y-6 max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold text-slate-900">Profile Settings</h1>
    <div class="bg-white/60 backdrop-blur-xl border border-white/60 rounded-2xl shadow-xl shadow-slate-200/40 p-8">
      <p class="text-slate-500">Profile configuration forms.</p>
    </div>
  </div>
ERB

files.each do |filename, content|
  File.write(filename, content)
  puts "Created #{filename}"
end
