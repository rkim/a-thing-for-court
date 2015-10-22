#!/usr/bin/env ruby
#
# -----------------------------------------------------------------------------
# Copyright (c) 2015 Roy Kim <kim.roy@gmail.com>
#
# @version v0.0.1
# @link http://github.com/rkim/a-thing-for-court
# @license MIT License, http://www.opensource.org/licenses/MIT
# -----------------------------------------------------------------------------
#
# Script to walk sub-directories and convert / copy supported audio files to
# .mp3s using ffmpeg
#
# -----------------------------------------------------------------------------

require 'fileutils'

READ_DIR = "./test"
OUTPUT_DIR = "~/Music/Converted"
BIT_RATE = "320k"

# Supported audio formats
SUPPORTED_FORMATS = [
  ".m4a",
  ".m4p",
  ".wav",
  ".m4r",
  ".wma",
  ".aif"
]

# File formats to be copied
COPY_FORMATS = [
 ".mp3",
 ".pdf",
 ".ini",
 ".jpg",
 ".png",
 ".xml",
 ".css",
 ".txt",
 ".ovw",
 ".db",
 ".cab",
 ".html",
 ".tiff",
 ".plist",
 ".band"
]

# Audio files in Court's music directory match the following regex pattern
PATTERN = /^(\._\d|_\d|\.d|\d)/


#
#
def get_all_files(dir)
  files = Dir[ File.join(".", '**', '*') ].reject { |p| File.directory? p }
end

#
#
def get_files_to_convert(files)
  music_files = files.select{|f| SUPPORTED_FORMATS.any?{|fmt| f.include? fmt}}
end

#
#
def get_files_to_copy(files)
  non_music_files = files.select{|f| COPY_FORMATS.any?{|fmt| f.include? fmt}}
end

#
#
def setup_for_processing
  # Make sure the output directory is present
  path = File.expand_path(OUTPUT_DIR)
  FileUtils.mkdir_p(path)
end

#
#
def get_destination_path(full_path)
  path = nil
  
  # 1. Remove READ_DIR from the path
  if full_path.index(READ_DIR) == 0
    start_index = READ_DIR.length
    end_index = full_path.length

    path = full_path[start_index...end_index]
  end

  # 2. Find the path
  index = path.rindex(/\//)
  path = path[0...index]

  # 3. Expand OUTPUT_DIR and concatenate
  path = File.expand_path(OUTPUT_DIR) + "/" + path
  File.expand_path(path)
end



def get_filename(full_path)
  # 2. Find the path
  start_index = 1 + full_path.rindex(/\//)
  end_index = full_path.length

  file_name = full_path[start_index...end_index]
end



#
#
def copy_files_to_dest(files_to_copy)
  puts "============================"
  puts "= Copying files...         ="
  puts "============================"
  puts ""

  processed = 0
  total_files = files_to_copy.length

  files_to_copy.each do |f|
    dest_path = get_destination_path(f)
    file_name = get_filename(f)

    print "[ #{processed} / #{total_files} ] :  "
    print dest_path + "/" + file_name + "\r\n"
    #FileUtils.mkdir_p(dest_path)
    #FileUtils.cp(f, dest_path)

    $stdout.flush
    sleep 0.01

    processed += 1
  end

end

#
#
def convert_files_to_dest(files_to_convert)
  puts "============================"
  puts "= Converting...            ="
  puts "============================"
  puts ""

  processed = 0
  total_files = files_to_convert.length

  files_to_convert.each do |f|

    # Extract parts from full file path
    dest_path = get_destination_path(f)
    file_name = get_filename(f)

    # Construct new path and file name (with the appropriate file type).
    # This is a bit fragile. Might need to beef it up.
    file_type_index = SUPPORTED_FORMATS.map{|fmt| file_name.rindex fmt}.compact.uniq.first
    dest_file = dest_path + "/" + file_name[0...file_type_index] + ".mp3"

    #print "[ #{processed} / #{total_files} ] :  "
    #print dest_path + "/" + file_name + "\r\n"

    # Execute conversion
    begin
      command = "ffmpeg -i \"#{f}\" -ab #{BIT_RATE} -map_metadata 0 \"#{dest_file}\"";
      print command + "\n"
    rescue

    end

    # Output results and continue
    #
    #
    #
    #

    $stdout.flush
    sleep 0.01

    processed += 1
  end

end

#
#
def run
  all_files = get_all_files(READ_DIR)
  music_files = get_files_to_convert(all_files)
  non_music_files = get_files_to_copy(all_files)

  setup_for_processing

  #copy_files_to_dest(non_music_files)
  convert_files_to_dest(music_files)
end

run

