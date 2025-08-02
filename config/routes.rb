Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :documents, only: [:create, :show]
    end
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  root "home#index"
end
