Rails.application.routes.draw do
  resources :service_packs do
  	resources :mapping_rates
  end
end