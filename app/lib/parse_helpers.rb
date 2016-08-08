module ParseHelpers

  class CreateAudioEntry
    def initialize(filename, user)
      track = $parse.object("SpotlightUserUploadedAudio")
      track['filename'] = filename
      track['user_id'] = user.id
      track.save

      track.array_add_relation("uploader", user.pointer)
      track.save
      @track = track
    end

    def parse_pointer
      @track.pointer
    end

    def parse_id
      @track.id
    end
  end

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
    def initialize(user, video_objects, audio_object = nil)
      video = $parse.object("SpotlightCombinedVideo")
      video['user_id'] = user.id
      video['combined'] = false
      video.save

      video_pointers = video_objects.map(&:parse_pointer)
      video_pointers.each do |pointer|
        video.array_add_relation("videos", pointer)
      end

      video_ids = video_objects.map(&:parse_id).flatten
      video_ids.each do |video_id|
        video.array_add("video_ids", video_id)
      end

      if audio_object.present?
        puts "audio object: #{audio_object}"
        audio_id = audio_object.parse_id
        audio_pointer = audio_object.parse_pointer
        video.array_add_relation("audio", audio_pointer)
        video['audio_id'] = audio_id
        video.save
      end

      video.save
      @video = video
    end

    def parse_id
      @video.id
    end

    def parse_pointer
      @video.pointer
    end

  end

  class CombinedVideoEntry
    def self.find(id)
      query = $parse.query("SpotlightCombinedVideo").eq("objectId", id)
      query.get.first
    end
  end

  class UserEntry
    def self.find(id)
      query = $parse.query("_User").eq("objectId", id)
      query.get.first
    end

    def self.find_user_uploaded_videos(id)
      $parse.query("SpotlightUserUploadedVideo").tap do |q|
        q.eq("user_id", id)
        q.order_by = "createdAt"
        q.order = :descending
      end.get
    end

    def self.find_combined_videos(id)
      $parse.query("SpotlightCombinedVideo").tap do |q|
        q.eq("user_id", id)
        q.eq("combined", true)
        q.order_by = "createdAt"
        q.order = :descending
      end.get
    end
  end

  class AudioEntry
    def self.find(id)
      res = find_in_parse(id)
      res
    end

    def self.get_public_url(filename)
      $s3_bucket.object("uploads/#{filename}").public_url
    end

    private
    def self.find_in_parse(id)
      query = $parse.query("SpotlightUserUploadedAudio").eq("objectId", id)
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
