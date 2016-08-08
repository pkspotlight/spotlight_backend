class UserController < ApplicationController
  before_action :ensure_user_id_exists
  before_action :ensure_user_exists

  def videos
    user_uploaded_videos = get_user_uploaded_videos.map do |video|
      user_submitted_display_helper(video)
    end

    combined_videos = get_combined_videos.map do |video|
      combined_video_display_helper(video)
    end

    render status: 200, json: {user_uploaded: user_uploaded_videos, combined: combined_videos}
  end

  private

  def get_user_uploaded_videos
    UserEntry.find_user_uploaded_videos(@user_id)
  end

  def get_combined_videos
    UserEntry.find_combined_videos(@user_id)
  end

  def get_video_link(filename)
    VideoEntry.get_public_url(filename)
  end

  def user_submitted_display_helper(parse_obj)
    res = {}
    res[:created_at] = Time.parse(parse_obj['createdAt']).to_i
    res[:url] = get_video_link(parse_obj['filename'])
    res[:description] = parse_obj['description']
    res[:video_id] = parse_obj['objectId']

    res
  end

  def combined_video_display_helper(parse_obj)
    res = {}
    res[:created_at] = Time.parse(parse_obj['createdAt']).to_i
    res[:url] = get_video_link(parse_obj['filename'])
    res[:description] = parse_obj['description']
    res[:video_id] = parse_obj['objectId']
    res[:source_video_ids] = parse_obj['video_ids']
    res[:exists] = parse_obj['combined']

    res
  end
end
