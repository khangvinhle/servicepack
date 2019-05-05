# frozen_string_literal: true
# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::ServicePacks
  class Engine < ::Rails::Engine
    engine_name 'openproject-service_packs'

    include OpenProject::Plugins::ActsAsOpEngine

    register('openproject-service_packs',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 6.0.0') do

      project_module :service_packs do
        # permission :view_ServicePacks, {ServicePacks: [:index]}
        # permission :create_ServicePacks, {ServicePacks: [:new, :create]}
        # permission :update_ServicePacks, {ServicePacks: [:edit]}
        # permission :delete_ServicePacks, {ServicePacks: [:destroy]}
        permission :assign_service_packs, {assigns: [:assign, :index]}, require: :member
        permission :unassign_service_packs, {assigns: [:unassign, :index]}, require: :member
        permission :see_assigned_service_packs, {assigns: [:index], sp_report: [:report]}, require: :member
      end

      menu :admin_menu,
           :service_packs,
           { controller: '/service_packs', action: 'index' },
           after: :overview,
           param: :project_id,
           caption: 'Service Packs',
           icon: 'icon2 icon-settings',
           html: {id: 'service_packs-menu-item'}
           # if: ->(project) {true}

      menu :project_menu,
           :assigns,
           {controller: '/assigns', action: 'index'},
           after: :overview,
           param: :project_id,
           caption: 'Service Packs Assignment',
           icon: 'icon2 icon-settings',
           html: {id: 'assign-menu-item'}

      menu :project_menu,
           :sp_report,
           {controller: 'sp_report', action: 'report'},
           after: :assigns,
           param: :project_id,
           caption: 'Service Pack Report',
           icon: 'icon2 icon-unordered-list',
           html: {id: 'report-sp-menu-item'}
    end
    patches %i[Project TimeEntryActivity TimeEntry Enumeration]
    assets %w(assigns.js service_packs.js assigns.css service_packs.css)

    initializer 'service_packs.register_hooks' do
      require 'open_project/service_packs/hooks'
    end

    config.to_prepare do
      # Getting service_pack_id into time_entry
      require 'open_project/service_packs/patches/permitted_params_patch'
      require 'open_project/service_packs/patches/base_contract_patch'

      TimeEntries::BaseContract.send(:include, OpenProject::ServicePacks::Patches::BaseContractPatch)
      # prepend has higher priority.
      PermittedParams.send(:prepend, OpenProject::ServicePacks::Patches::PermittedParamsPatch)
    end
  end
end
# preserve lost path: no, you can't add a new tab into project settings from the plugin extension.
# add_tab_entry :project_settings, name: "service_packs", partial: "assigns/show", label: :caption_service_pack
