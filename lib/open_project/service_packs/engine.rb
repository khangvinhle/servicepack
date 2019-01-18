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

      project_module :service_packs do
        # permission :view_ServicePacks, {ServicePacks: [:index]}
        # permission :create_ServicePacks, {ServicePacks: [:new, :create]}
        # permission :update_ServicePacks, {ServicePacks: [:edit]}
        # permission :delete_ServicePacks, {ServicePacks: [:destroy]}
        permission :assign_Service_Packs, { assigns: [:assign, :show] }
        permission :unassign_Service_Packs, { assigns: [:unassign, :show] }
      end

      menu :project_menu,
           :assigns,
           { controller: '/assigns', action: 'show' },
           after: :overview,
           param: :project_id,
           caption: 'Service packs assignment',
           icon: 'icon2 icon-bug',
           html: { id: 'assign-menu-item' },
           icon: 'icon2 icon-bug',
           if: ->(project) {true} # todo: must turn on SP module first

      menu :admin_menu,
           :service_packs,
           { controller: '/service_packs', action: 'index' },
           after: :overview,
           param: :project_id,
           caption: 'Service Packs',
           icon: 'icon2 icon-bug',
           html: {id: 'service_packs-menu-item'}
      # if: ->(project) {true}
    
    end
    

    patches %i[Project TimeEntryActivity TimeEntry]
  
  end
end
