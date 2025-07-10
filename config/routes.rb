Rails.application.routes.draw do
  resources :inventory_locations
  resources :tags
  namespace :inventory do
    get "cards/staging" => "cards#staging"
    post "cards/process_import_for_staging" => "cards#process_import_for_staging"
    post "cards/clear_staging" => "cards#clear_staging"
    post "cards/upload_csv" => "cards#upload_csv"
    post "cards/delete_from_csv" => "cards#delete_from_csv"
    post "cards/convert_to_inventory" => "cards#convert_to_inventory"
    resources :cards
  end
  resources :card_metadata

  # Admin routes
  namespace :admin do
    # GoodJob dashboard for monitoring background jobs
    mount GoodJob::Engine => "jobs"

    # Scryfall data management
    resource :scryfall, only: [ :show ], controller: "scryfall" do
      member do
        post :sync
        post :force_sync
        get :status
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "inventory/cards#index"
end
