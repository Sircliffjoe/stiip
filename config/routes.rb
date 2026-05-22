Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users

  resources :companies, param: :ticker_symbol, only: [:index, :show]
  resources :dividends, only: [:index]
  resources :news_articles, param: :slug, only: [:index, :show], path: 'news'
  resources :educational_contents, param: :slug, only: [:index, :show], path: 'learn'
  resources :watchlists do
    resources :watchlist_items, only: [:create, :destroy]
  end
  resources :notifications, only: [:index, :update] do
    collection do
      patch :mark_all_read
    end
  end
  
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
    resources :news_articles, path: "news"
    resources :educational_contents, path: "learn"
    resources :data_imports, only: [:index] do
      collection do
        post :sync_prices
        post :sync_dividends
        post :sync_news
        post :import_csv
      end
    end
  end
  
  namespace :api do
    namespace :v1 do
      resources :companies, only: [:index, :show] do
        resources :prices, only: [:index]
      end
    end
  end
  
  namespace :webhooks do
    post 'subscriptions', to: 'subscriptions#create'
  end

  get '/profile', to: 'profiles#edit'
  get '/search', to: 'search#index'
  get '/market', to: 'market#index'
  get '/dashboard', to: 'dashboard#index'

  root "pages#home"
end
