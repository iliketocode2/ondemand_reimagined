# frozen_string_literal: true

# Controller for the Appverse home page — a browsable grid of locally installed
# HPC apps alongside the community catalog from openondemand.connectci.org.
class AppverseController < ApplicationController
  def index
    @installed_apps  = installed_app_list
    @catalog_apps    = Appverse::CatalogService.all
    @catalog_error   = @catalog_apps.empty?

    # Build a set of lowercase installed titles for O(1) lookup in the view.
    @installed_title_set = @installed_apps.flat_map do |app|
      app.links.map { |l| l.title.to_s.downcase }
    end.to_set
  end

  private

  # Flat list of all OodApp objects the current user can access, ordered by
  # most recently used first (approximated by the existing nav ordering).
  def installed_app_list
    all = nav_sys_apps
    all += nav_dev_apps if ::Configuration.app_development_enabled?
    all += nav_usr_apps if ::Configuration.app_sharing_enabled?
    all
  end
end
