Rails.application.routes.draw do
  get "manifest.json" => "pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker.js" => "pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }

  get '/screener', to: 'screener#index'
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
  resources :api_keys, only: [:index, :create, :destroy]

  # Pricing & Subscriptions
  resources :pricing, only: [:index] do
    collection do
      post :checkout
      get :callback
    end
  end

  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    get 'records', to: 'records#index', as: :records
    get 'records/:model', to: 'records#model_index', as: :records_model
    post 'records/:model', to: 'records#create'
    get 'records/:model/new', to: 'records#new', as: :new_record
    get 'records/:model/:id', to: 'records#show', as: :record
    get 'records/:model/:id/edit', to: 'records#edit', as: :edit_record
    patch 'records/:model/:id', to: 'records#update'
    put 'records/:model/:id', to: 'records#update'
    delete 'records/:model/:id', to: 'records#destroy'
    resources :users do
      member do
        patch :confirm
      end
    end
    resources :companies
    resources :subscriptions
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
        resources :dividends, only: [:index]
      end
      resources :dividends, only: [:index]
      resources :news, only: [:index, :show], controller: 'news'
      get :search, to: 'search#index'
    end
  end
  
  namespace :webhooks do
    post 'subscriptions', to: 'subscriptions#create'
    post 'paystack', to: 'paystack#create'
  end

  get '/profile', to: 'profiles#show'
  get '/settings', to: 'profiles#edit'
  patch '/settings', to: 'profiles#update'
  put '/settings', to: 'profiles#update'
  get '/search', to: 'search#index'
  get '/pricing', to: 'pricing#index'
  get '/market', to: 'market#index'
  get '/dashboard', to: 'dashboard#index'

  # Static pages
  get '/about', to: 'pages#about'
  get '/features', to: 'pages#features'
  get '/contact', to: 'pages#contact'
  get '/terms', to: 'pages#terms'
  get '/privacy', to: 'pages#privacy'
  get '/disclaimer', to: 'pages#disclaimer'

  root "pages#home"
end
