module OpenProject::ServicePacks
	class Hooks < Redmine::Hook::ViewListener
		render_on :view_timelog_edit_form_bottom,
				  partial: -'hooks/select_service_pack_on_timelog'
	end
end