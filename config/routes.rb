OpenProject::Application.routes.draw do
  resources :service_packs do
  	resources :mapping_rates
  end
  scope "/projects/:project_id" do
  	resources :assigns
  end
end