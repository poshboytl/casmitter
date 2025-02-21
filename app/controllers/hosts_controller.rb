class HostsController < ApplicationController
  def show
    # TODO: use permalink instead of id
    @host = Host.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Host not found"
    redirect_to root_path
  end
end 