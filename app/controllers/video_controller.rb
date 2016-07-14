class VideoController < ApplicationController

  def upload
    files = get_all_video_files

    uploader = ContentUploader.new

    files.each do |file|
      str = generate_unique_string(file.object_id)
      new_name = file.original_filename + str
      file.original_filename = new_name
      uploader.store!(file)
    end
    render status: 200, json: { success: true }
  end

  private

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
