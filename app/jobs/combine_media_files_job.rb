class CombineMediaFilesJob < ApplicationJob
  include ParseHelpers
  queue_as :urgent

  def write_videos(video_ids, dir)
    require 'open-uri'

    videos_to_merge = []
    video_ids.each do |vid_id|
      video_entry = VideoEntry.find(vid_id)
      filename = video_entry['filename']
      videos_to_merge << filename
      public_url = VideoEntry.get_public_url(filename)
      open("#{dir}/#{filename}", 'wb') do |file|
        file << open(public_url).read
      end
    end
    videos_to_merge.uniq
  end

  def write_audio(audio_id, dir)
    require 'open-uri'

    audio_entry = AudioEntry.find(audio_id)
    filename = audio_entry['filename']
    audio_to_merge = filename
    public_url = AudioEntry.get_public_url(filename)
    open("#{dir}/#{filename}", 'wb') do |file|
      file << open(public_url).read
    end
    audio_to_merge
  end

  def merge_files(combined_video, videos_to_merge, dir)
    output_filename = "#{dir}/#{combined_video.id}.mp4"
    videos_to_merge_string = videos_to_merge.map do |str|
      "#{dir}/#{str}"
    end.join(' ')
    command = "#{dir}/spotlight_cat #{videos_to_merge_string} #{output_filename} > /dev/null 2>&1"
    system command
  end

  def add_audio(combined_video, audio_file, dir)
    output_filename = "#{dir}/#{combined_video.id}.mp4"
    temporary_filename = "#{dir}/a#{combined_video.id}.mp4"
    audio_file_to_merge = "#{dir}/#{audio_file}"

    command = %Q(ffmpeg -y -i #{output_filename} -i #{audio_file_to_merge} -filter_complex "[0:a][1:a]amerge=inputs=2[a]" -map 0:v -map "[a]" -c:v copy -c:a libvorbis -ac 2 -shortest #{temporary_filename} > /dev/null 2>&1)

    system command
    FileUtils.mv(temporary_filename, output_filename)
  end

  def perform(*args)
    id = args.first
    combined_video = CombinedVideoEntry.find(id)

    Dir.mktmpdir do |dir|
      create_merge_script(dir)
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

  def create_merge_script(dir)
    puts "creating merge script"
    script = %q(#!/bin/bash
TMP=/tmp
first=${@:1:1}
last=${@:$#:1}
len=$(($#-2))
inputs=${@:2:$len}

rm -f $TMP/mcs_*

mkfifo $TMP/mcs_a1 $TMP/mcs_v1

ffmpeg -y -i $first -vn -f u16le -acodec pcm_s16le -ac 2 -ar 44100 $TMP/mcs_a1 2>/dev/null </dev/null &
ffmpeg -y -i $first -an -f yuv4mpegpipe -vcodec rawvideo $TMP/mcs_v1 2>/dev/null </dev/null &


all_a=$TMP/mcs_a1
all_v=$TMP/mcs_v1
i=2
for f in $inputs
do
	mkfifo $TMP/mcs_a$i $TMP/mcs_v$i

	ffmpeg -y -i $f -vn -f u16le -acodec pcm_s16le -ac 2 -ar 44100 $TMP/mcs_a$i 2>/dev/null </dev/null &
	{ ffmpeg -y -i $f -an -f yuv4mpegpipe -vcodec rawvideo - 2>/dev/null </dev/null | tail -n +2 > $TMP/mcs_v$i ; } &
	all_a="$all_a $TMP/mcs_a$i"
	all_v="$all_v $TMP/mcs_v$i"
	let i++
done

mkfifo $TMP/mcs_a_all
mkfifo $TMP/mcs_v_all
cat $all_a > $TMP/mcs_a_all &
cat $all_v > $TMP/mcs_v_all &

ffmpeg -f u16le -acodec pcm_s16le -ac 2 -ar 44100 -i $TMP/mcs_a_all \
       -f yuv4mpegpipe -vcodec rawvideo -i $TMP/mcs_v_all \
	$EXTRA_OPTIONS \
	$last

rm -f $TMP/mcs_*)

    File.open("#{dir}/spotlight_cat", "w") do |f|
      f.write(script)
    end
    system "chmod +x #{dir}/spotlight_cat"
    FileUtils.cp("#{dir}/spotlight_cat", "/tmp/test/")
  end
end
