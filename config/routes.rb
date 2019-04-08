# freeze_literal_string: true

OpenProject::Application.routes.draw do
  resources :service_packs do
  	get '/statistics', to: 'service_packs#statistics', constraints: lambda { |req| req.format == :json }
  end
  scope '/projects/:project_id' do
  	get '/assigns', to: 'assigns#show'
    get '/assigns/report', to: 'assigns#report'
  	post '/assigns/assign', to: 'assigns#assign'
  	post '/assigns/unassign', to: 'assigns#unassign'
  	get '/assigns/statistics', to: 'assigns#statistics', constraints: lambda { |req| req.format == :json }
  	
    get '/sp_report', to: 'sp_report#report', as: 'sp_report'
  end
end