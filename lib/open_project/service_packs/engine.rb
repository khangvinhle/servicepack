# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ServicePacks
  class Engine < ::Rails::Engine
    engine_name :openproject_service_packs

    include OpenProject::Plugins::ActsAsOpEngine

    register('openproject-service_packs',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0') do

      project_module :ServicePacks_module do
        # permission :view_ServicePacks, {ServicePacks: [:index]}
        # permission :create_ServicePacks, {ServicePacks: [:new, :create]}
        # permission :update_ServicePacks, {ServicePacks: [:edit]}
        # permission :delete_ServicePacks, {ServicePacks: [:destroy]}
        permission :assign_ServicePacks, {project_assign: [:assign]}, require: :member
        permission :unassign_ServicePacks, {project_unassign: [:unassign]}, require: :member
      end

      menu :admin_menu,
           :service_packs,
           {controller: '/service_packs', action: 'index'},
           after: :overview,
           param: :project_id,
           caption: 'Service Packs',
           icon: 'icon2 icon-bug',
           html: {id: 'service_packs-menu-item'}
      # if: ->(project) {true}

      menu :project_menu,
           :assign,
           {controller: '/assigns', action: 'show'},
           after: :overview,
           param: :project_id,
           caption: 'project SP assign main page',
           html: {id: 'assign-menu-item'}
           # if: ->(project) {true} # todo: must turn on SP module first
    end
    patches %i[Project TimeEntryActivity TimeEntry]
  end
end
