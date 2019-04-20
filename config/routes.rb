# frozen_string_literal: true
OpenProject::Application.routes.draw do
  resources :service_packs do
    get '/statistics', to: 'service_packs#statistics', constraints: lambda { |req| req.format == :json }
  end
  scope '/projects/:project_id' do
    get '/sp_report', to: 'sp_report#report'
    get '/assigns/assign', to: 'assigns#to_assign'
    post '/assigns/assign', to: 'assigns#assign'
    post '/assigns/unassign/:service_pack_id', to: 'assigns#unassign'
    get '/assigns/', to: 'assigns#index'
  end
end