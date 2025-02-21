class GuestsController < ApplicationController
  def show
    @guest = Guest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Guest not found"
    redirect_to root_path
  end
end 