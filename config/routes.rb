OpenProject::Application.routes.draw do
  resources :service_packs do
  	get '/statistics', to: 'service_packs#statistics', constraints: lambda { |req| req.format == :json }
  end
  scope "/projects/:project_id" do
  	get '/assigns', to: 'assigns#show'
  	post '/assigns/assign', to: 'assigns#assign'
  	post '/assigns/unassign', to: 'assigns#unassign'
  end
end