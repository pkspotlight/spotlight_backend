class VideoController < ApplicationController

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
    audio_track = get_audio_track.first

    uploader = ContentUploader.new

    object_ids = []
    video_objects = []
    files.each do |file|
      str = generate_unique_string(file.object_id)
      file.original_filename = str + file.original_filename
      file.original_filename = file.original_filename.gsub(' ', '')
      uploader.store!(file)

      video_objects << CreateVideoEntry.new(file.original_filename, @user)
    end

    audio_entry = nil
    if (audio_track.present?)
      str = generate_unique_string(audio_track.object_id)
      audio_track.original_filename = str + audio_track.original_filename
      audio_track.original_filename = audio_track.original_filename.gsub(' ', '')
      uploader.store!(audio_track)

      audio_entry = CreateAudioEntry.new(audio_track.original_filename, @user)
    end
    entry = CreateCombinedVideoEntry.new(@user, video_objects, audio_entry)

    CombineMediaFilesJob.perform_later(entry.parse_id)

    object_ids = video_objects.map(&:parse_id)

    res = {}
    if audio_track.present?
      audio_id = audio_entry.parse_id
      res = { success: true,
              audio_id: audio_id,
              video_ids: object_ids,
              combined_video_id: entry.parse_id }
    else
      res = { success: true, video_ids: object_ids, combined_video_id: entry.parse_id }
    end

    render status: 200, json: res
  end

  private

  def generate_unique_string(object_id)
    "#{object_id}#{('a'..'z').to_a.shuffle[0,8].join}"
  end

  def get_audio_track
    res = []
    filenames = []
    params.keys.each do |key|
      if key.include? "audio"
        filenames << key
      end
    end

    filenames.each do |filename|
      res << params[filename]
    end
    res
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
