class VideoController < ApplicationController
  include ParseHelpers

  before_action :ensure_user_id_exists
  before_action :ensure_user_exists
  before_action :ensure_relevant_metadata_exists, only: [:upload]
  before_action :ensure_video_id_exists, only: [:find]
  before_action :ensure_video_exists, only: [:find]
  before_action :ensure_user_can_view_video, only: [:find]

  def find
    res = {}
    status = 200

    res[:url] = VideoEntry.get_public_url(@video_entry['filename'])

    render status: status, json: res
  end

  def upload
    files = get_all_video_files
    uploader = ContentUploader.new

    object_ids = []
    video_objects = []
    files.each do |file|
      str = generate_unique_string(file.object_id)
      new_name = file.original_filename + str
      file.original_filename = new_name
      uploader.store!(file)

      video_objects << CreateVideoEntry.new(new_name, @user)
    end
    CreateCombinedVideoEntry.new(@user, video_objects)
    object_ids = video_objects.map(&:parse_id)

    render status: 200, json: { success: true, object_ids: object_ids }
  end

  private

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

  def generate_unique_string(object_id)
    "#{object_id}#{('a'..'z').to_a.shuffle[0,8].join}"
  end

  def get_all_video_files
    res = []
    filenames = []
    params.keys.each do |key|
      if key.include? "video"
        filenames << key
      end
    end

    filenames.each do |filename|
      res << params[filename]
    end
    res
  end
end
