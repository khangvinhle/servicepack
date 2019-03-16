OpenProject::Application.routes.draw do
  resources :service_packs do
  	get '/statistics', to: 'service_packs#statistics', constraints: lambda { |req| req.format == :json }
  end
  scope "/projects/:project_id" do
  	get '/assigns', to: 'assigns#show'
  	post '/assigns/assign', to: 'assigns#assign'
  	post '/assigns/unassign', to: 'assigns#unassign'
  	get '/assigns/transfer', to: 'assigns#transfer'
  	get '/assigns/statistics', to: 'assigns#statistics', constraints: lambda { |req| req.format == :json }
  	get '/assigns/:assignment_id/transfer', to: 'assigns#select_to_transfer', as: 'sp_transfer'
  end
end