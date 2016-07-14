class ListVideosController < ApplicationController

  def status
    render json: { success: true }
  end
end
