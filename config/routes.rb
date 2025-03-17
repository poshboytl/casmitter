Rails.application.routes.draw do
  # a workaround for redirecting a wrong episode link to the correct one
  get 'episodes/167', to: redirect('/episodes/1')
  
  # resource :session
  # resources :passwords, param: :token
  resources :episodes, only: [:show, :index]
  resources :hosts, only: [:show]
  resources :guests, only: [:show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "episodes#index"

  # long live RSS!!!
  get 'feed' => 'episodes#index', :defaults => { :format => 'rss' }
  get 'rss'  => 'episodes#index', :defaults => { :format => 'rss' }

end
