Rails.application.routes.draw do
  namespace :api do
    resources :event_types, only: %i[index create] do
      get :availability, on: :member
    end
    resources :bookings, only: :create do
      get :upcoming, on: :collection
    end
  end

  scope module: :web do
    root "home#index"
    get "booking", to: "pages#booking"
    get "admin", to: "pages#admin"
    get "admin/event_types/new", to: "pages#new_event_type", as: :new_admin_event_type
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
