module ParseHelpers
  class CreateVideoEntry
    def initialize(filename, user)
      video = $parse.object("SpotlightUserUploadedVideo")
      video['filename'] = filename
      video['user_id'] = user.id
      video.save

      video.array_add_relation("uploader", user.pointer)
      video.save
      @video = video
    end

    def parse_pointer
      @video.pointer
    end

    def parse_id
      @video.id
    end
  end

  class CreateCombinedVideoEntry
    def initialize(user, video_objects)
      video = $parse.object("SpotlightCombinedVideo")
      video['user_id'] = user.id
      video['combined'] = false
      video.save

      video_pointers = video_objects.map(&:parse_pointer)
      video_pointers.each do |pointer|
        video.array_add_relation("videos", pointer)
      end
      video.save
    end
  end

  class UserEntry
    def self.find(id)
      query = $parse.query("_User").eq("objectId", id)
      query.get.first
    end
  end

  class VideoEntry
    def self.find(id)
      res = find_in_parse(id)
      res
    end

    def self.get_public_url(filename)
      $s3_bucket.object("uploads/#{filename}").public_url
    end

    private
    def self.find_in_parse(id)
      query = $parse.query("SpotlightUserUploadedVideo").eq("objectId", id)
      query.get.first
    end
  end
end
