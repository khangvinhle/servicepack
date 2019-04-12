# frozen_string_literal: true
OpenProject::Application.routes.draw do
  resources :service_packs do
  	get '/statistics', to: 'service_packs#statistics', constraints: lambda { |req| req.format == :json }
  end
  scope '/projects/:project_id' do
    get '/assigns/report', to: 'assigns#report'
  	post '/assigns/assign', to: 'assigns#assign'
  	post '/assigns/unassign', to: 'assigns#unassign'
  	get '/assigns/statistics', to: 'assigns#statistics', constraints: lambda { |req| req.format == :json }
    get '/assigns/', to: 'assigns#index'
  end
end