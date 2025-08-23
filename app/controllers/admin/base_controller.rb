class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :require_admin_authentication

  private

  def require_admin_authentication
    unless authenticated? && Current.user
      redirect_to new_session_path, alert: "Admin access required"
    end
  end
end
