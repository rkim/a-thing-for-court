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

DEBUG = false

READ_DIR = "../"
BIN_DIR = "./bin"
WORKING_DIR = "./tmp"
OUTPUT_DIR = "~/Music/Converted"
ERROR_DIR = "~/Music/Errors"

CONVERT_TO = ".mp3"
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

  # This could be album art...
  ".jpg",
  ".png",
  ".tiff",

  # I found these other file types in your music directory, but I don't think
  # they need to be copied over.
  # ".pdf",
  # ".html",
  # ".xml",
  # ".css",
  # ".txt",
  # ".ini",
  # ".db",
  # ".cab",
  # ".plist",

  # Unsupported file formats
  # ".ovw",
  # ".band"
]

#
#
def get_all_files(dir)
  files = Dir[ File.join(dir, '**', '.*'), File.join(dir, '**', '*')].reject { |p| File.directory? p }
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
def get_destination_path(full_path, output_path = OUTPUT_DIR)
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

  # 3. Expand output_path and concatenate
  path = File.expand_path(output_path) + "/" + path
  File.expand_path(path)
end

#
#
def get_filename(full_path)
  # 2. Find the path
  start_index = 1 + full_path.rindex(/\//)
  end_index = full_path.length

  file_name = full_path[start_index...end_index]
end

#
#
def handle_errors(errors)
  puts "============================"
  puts "=                          ="
  puts "= Handling errors...       ="
  puts "=                          ="
  puts "============================\n"

  processed = 1
  total_files = errors.length

  errors.each do |f|
    dest_path = get_destination_path(f, ERROR_DIR)
    file_name = get_filename(f)

    print "[ #{processed} / #{total_files} ] :  "
    print dest_path + "/" + file_name + "\r\n"

    if !DEBUG
      FileUtils.mkdir_p(dest_path)
      FileUtils.cp(f, dest_path)
    end

    $stdout.flush
    sleep 0.01

    processed += 1
  end
end

#
#
def copy_files_to_dest(files_to_copy)
  puts "\n\n============================"
  puts "=                          ="
  puts "= Copying files...         ="
  puts "=                          ="
  puts "============================\n"

  processed = 1
  total_files = files_to_copy.length

  files_to_copy.each do |f|
    dest_path = get_destination_path(f)
    file_name = get_filename(f)
    dest_file = dest_path + "/" + file_name

    print "[ #{processed} / #{total_files} ] :  "
    print dest_file

    if File.file?(dest_file)
      print "  -- File already exists...skipping"
      @skipped << f
    elsif !DEBUG
      FileUtils.mkdir_p(dest_path)
      FileUtils.cp(f, dest_path)
    end

    print "\r\n"

    $stdout.flush
    sleep 0.01

    processed += 1
    @copied << f
  end

end

#
#
def convert_files_to_dest(files_to_convert)
  puts "\n\n============================"
  puts "=                          ="
  puts "= Converting...            ="
  puts "=                          ="
  puts "============================"

  processed = 1
  total_files = files_to_convert.length

  files_to_convert.each do |f|

    # Extract parts from full file path
    dest_path = get_destination_path(f)
    file_name = get_filename(f)
    next if dest_path.nil? || file_name.nil?

    # Let's also do a bit of work here to rename hidden files
    file_name[0] = "_" if file_name[0] == "."

    # Construct new path and file name (with the appropriate file type).
    begin
      file_type_index = SUPPORTED_FORMATS.map{|fmt| file_name.rindex fmt}.compact.uniq.first
      raise if file_type_index.nil?
    rescue
      @failed << f
      puts "\nERROR: Failed to parse file #{f}\n"
    end
    dest_file = dest_path + "/" + file_name[0...file_type_index] + CONVERT_TO

    puts "\n............................"
    print "[ #{processed} / #{total_files} ] :  "
    print f + "\r\n"

    # Skip if file already exists at the destination
    if File.file?(dest_file)
      puts "File already exists...skipping"
      puts "............................\n"
      @skipped << f
    # Else, convert the file
    else
      begin
        # Ensure the directory for the output file exists
        FileUtils.mkdir_p(dest_path)

        # Convert!
        temp_file = File.expand_path(WORKING_DIR) + "/tmp" + CONVERT_TO
        command = "#{BIN_DIR}/ffmpeg -i \"#{f}\" -ab #{BIT_RATE} -id3v2_version 3 \"#{temp_file}\"";
        puts command
        puts "............................\n"

        if !DEBUG
          result = %x[ #{command} ]
          print result
        end
      rescue
        @failed << f
        puts "\nERROR: Failed to convert file #{f}\n"
      
      else
        # Move temp file to destination path
        FileUtils.mv(temp_file, dest_file)
        @converted << f
      end
    end

    $stdout.flush
    sleep 0.01
    processed += 1
  end
end

#
#
def setup
  # Make sure the output directory is present
  output_path = File.expand_path(OUTPUT_DIR)
  FileUtils.mkdir_p(output_path)

  # Make sure the temp directory is present
  working_path = File.expand_path(WORKING_DIR)
  FileUtils.mkdir_p(working_path)

  true
end


def teardown
  # Delete working directory and it's contents
  working_path = File.expand_path(WORKING_DIR)
  FileUtils.rm_rf(working_path)

  true
end

def summary
  puts "\n\n"
  puts "============================"
  puts "= Processing complete!     ="
  puts "============================\n\n"
  print "Converted: #{@converted.length}\n"
  print "Copied:    #{@copied.length}\n"
  print "Skipped:   #{@skipped.length}\n"
  print "Failed:    #{@failed.length}\n\n"
end

#
#
def run
  # Kinda dirty, but Court will never know...
  @converted = []
  @copied = []
  @skipped = []
  @failed = []

  all_files = get_all_files(READ_DIR)
  music_files = get_files_to_convert(all_files)
  non_music_files = get_files_to_copy(all_files)

  setup
  if non_music_files && non_music_files.length > 0
    copy_files_to_dest(non_music_files)
  end

  if music_files && music_files.length > 0
    convert_files_to_dest(music_files)
  end

  if @failed.length > 0
    handle_errors(@failed)
  end

  teardown
  summary
end

run

