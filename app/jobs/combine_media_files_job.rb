class CombineMediaFilesJob < ApplicationJob
  include ParseHelpers
  queue_as :urgent

  def write_videos(video_ids, dir)
    require 'open-uri'

    videos_to_merge = []
    video_ids.each do |vid_id|
      video_entry = VideoEntry.find(vid_id)
      filename = video_entry['filename']
      p "filename #{filename}"
      videos_to_merge << filename
      public_url = VideoEntry.get_public_url(filename)
      open("#{dir}/#{filename}", 'wb') do |file|
        file << open(public_url).read
      end
    end
    videos_to_merge
  end

  def write_audio(audio_id, dir)
    require 'open-uri'

    audio_entry = AudioEntry.find(audio_id)
    filename = audio_entry['filename']
    p "audio filename #{filename}"
    audio_to_merge = filename
    public_url = AudioEntry.get_public_url(filename)
    open("#{dir}/#{filename}", 'wb') do |file|
      puts "public url is #{public_url}"
      file << open(public_url).read
    end
    audio_to_merge
  end

  def merge_files(combined_video, videos_to_merge, dir)
    output_filename = "#{dir}/#{combined_video.id}.mp4"
    videos_to_merge_string = videos_to_merge.map do |str|
      "#{dir}/#{str}"
    end.join(' ')
    command = "mmcat #{videos_to_merge_string} #{output_filename} > /dev/null 2>&1"
    system command
  end

  def add_audio(combined_video, audio_file, dir)
    output_filename = "#{dir}/#{combined_video.id}.mp4"
    temporary_filename = "#{dir}/a#{combined_video.id}.mp4"
    audio_file_to_merge = "#{dir}/#{audio_file}"

    command = %Q(ffmpeg -y -i #{output_filename} -i #{audio_file_to_merge} -filter_complex "[0:a][1:a]amerge=inputs=2[a]" -map 0:v -map "[a]" -c:v copy -c:a libvorbis -ac 2 -shortest #{temporary_filename})

    system command
    FileUtils.mv(temporary_filename, output_filename)
  end

  def perform(*args)
    id = args.first
    combined_video = CombinedVideoEntry.find(id)

    Dir.mktmpdir do |dir|
      output_filename = "#{dir}/#{combined_video.id}.mp4"

      videos_to_merge = write_videos(combined_video['video_ids'], dir)
      merge_files(combined_video, videos_to_merge, dir)

      if combined_video['audio_id'].present?
        audio_to_merge = write_audio(combined_video['audio_id'], dir)
        add_audio(combined_video, audio_to_merge, dir)
      end

      File.open(output_filename) do |f|
        uploader = ContentUploader.new
        uploader.store!(f)
      end

      combined_video['combined'] = true
      combined_video['filename'] = "#{combined_video.id}.mp4"
      combined_video.save
    end
  end
end
