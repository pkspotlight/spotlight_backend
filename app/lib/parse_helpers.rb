module ParseHelpers
  class CreateVideoEntry

    def initialize(filename, user_id)
      puts "received: #{filename} #{user_id}"
      video = $parse.object("SpotlightUserUploadedVideo")
      video['filename'] = filename
      video['user_id'] = user_id
      result = video.save
      puts result
    end
  end
end
