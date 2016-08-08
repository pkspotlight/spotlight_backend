class ApplicationController < ActionController::API
  include ParseHelpers

  def ensure_user_can_view_video
    if !(@video_entry['user_id'] == @user_id)
      status = 400
      res = { success: false, errors: [ { video: "does not exist" }]}
      render status: status, json: res
    end
  end

  def ensure_video_exists
    id = params[:video_id]
    @video_entry = VideoEntry.find(id)

    if @video_entry.nil?
      status = 404
      res = { success: false, errors: [ { video: "does not exist" } ] }
      render status: status, json: res
    end
  end

  def ensure_video_id_exists
    id = params[:video_id]

    if id.nil?
      res = {success: false, errors: [ { video: "video id missing" } ] }
      status = 404
      render status: status, json: res
    end
  end

  def ensure_relevant_metadata_exists
    metadata = params[:metadata]

    render status: 404, json: {success: false, errors: [ { metadata: "is missing" } ] } if metadata.nil?
  end

  def ensure_user_id_exists
    @user_id = params[:user_id]

    render status: 404, json: { success: false, errors: [ { user_id: "is missing" }]} if @user_id.nil?
  end

  def ensure_user_exists
    @user = UserEntry.find(@user_id)
    if @user.nil?
      render status: 404, json: { success: false, errors: [ { user: "does not exist" }]}
    end
  end
end
