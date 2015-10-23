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

# -------------------------------------
# Globals
# -------------------------------------

DEBUG = false

READ_DIR = ARGV[0] == "--packaged" ? "../../../" : "../"
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


# -------------------------------------
# 
#
# -------------------------------------

#
# Returns an array of all file paths in the specified directory and its
# sub-directories
def get_all_files_in_directory(dir)
  return [] if dir.nil?
  files = Dir[File.join(dir, '**', '.*'), File.join(dir, '**', '*')].reject{|p| File.directory? p}
end

#
# Returns an array of all file paths of convertible audio files
def get_files_to_convert(files)
  return [] if files.nil? || files.empty?
  music_files = files.select{|f| SUPPORTED_FORMATS.any?{|fmt| f.include? fmt}}
end

#
# Returns an array of all file paths of copyable files
def get_files_to_copy(files)
  return [] if files.nil? || files.empty?
  non_music_files = files.select{|f| COPY_FORMATS.any?{|fmt| f.include? fmt}}
end

#
#
def get_destination_dir(full_path, output = OUTPUT_DIR)
  path = nil
  
  # Remove READ_DIR from the path
  if full_path.index(READ_DIR) == 0
    i = READ_DIR.length
    j = full_path.length

    path = full_path[i...j]
  end

  # Remove file name from the path
  i = path.rindex(/\//)
  dir = i >= 0 ? path[0...i] : path

  # Expand build and sanitize destination directory
  dir = File.expand_path(output) + "/" + dir
  File.expand_path(dir)
end

#
#
def get_file_name(full_path)
  i = 1 + full_path.rindex(/\//)
  j = full_path.length

  file_name = i > 0 ? full_path[i...j] : full_path
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
    dest_dir = get_destination_dir(f, ERROR_DIR)
    file_name = get_file_name(f)

    print "[ #{processed} / #{total_files} ] :  "
    print dest_dir + "/" + file_name + "\r\n"

    if !DEBUG
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(f, dest_dir)
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
    dest_dir = get_destination_dir(f)
    file_name = get_file_name(f)
    dest_path = dest_dir + "/" + file_name

    print "[ #{processed} / #{total_files} ] :  "
    print dest_path

    if File.file?(dest_path)
      print "  -- File already exists...skipping"
      @skipped << f
    elsif !DEBUG
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(f, dest_dir)
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
    dest_dir = get_destination_dir(f)
    file_name = get_file_name(f)
    if dest_dir.nil? || file_name.nil?
      @failed << f
      puts "\nERROR: Failed to parse file #{f}\n"
      next
    end

    # Let's rename any 'hidden' audio files
    file_name[0] = "_" if file_name[0] == "."

    # Construct new path and file name (with the appropriate file type).
    begin
      file_type_index = SUPPORTED_FORMATS.map{|fmt| file_name.rindex fmt}.compact.uniq.first
      raise if file_type_index.nil?
    rescue
      @failed << f
      puts "\nERROR: Failed to parse file #{f}\n"
    end
    dest_path = dest_dir + "/" + file_name[0...file_type_index] + CONVERT_TO

    puts "\n............................"
    print "[ #{processed} / #{total_files} ] :  "
    print f + "\r\n"

    # Skip if file already exists at the destination
    if File.file?(dest_path)
      puts "File already exists...skipping"
      puts "............................\n"
      @skipped << f

    # Else, convert the file
    else
      begin
        # Ensure the directory for the output file exists
        FileUtils.mkdir_p(dest_dir)

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
        # Conversion complete, move temp file to destination path
        FileUtils.mv(temp_file, dest_path)
        @converted << f
      end
    end

    $stdout.flush
    sleep 0.01
    processed += 1
  end
end

#
# Make sure the output and working directories are present
def setup
  output_dir = File.expand_path(OUTPUT_DIR)
  FileUtils.mkdir_p(output_dir)

  working_dir = File.expand_path(WORKING_DIR)
  FileUtils.mkdir_p(working_dir)

  true
end

#
# Deletes temporary files and directories
def teardown
  working_dir = File.expand_path(WORKING_DIR)
  FileUtils.rm_rf(working_dir)

  true
end

#
# Displays a summary of files processed
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
# Entry point for execution
def main
  
  # Kinda dirty, but Court will never know...
  @converted = []
  @copied = []
  @skipped = []
  @failed = []

  all_files = get_all_files_in_directory(READ_DIR)
  music_files = get_files_to_convert(all_files)
  non_music_files = get_files_to_copy(all_files)

  setup

  if !non_music_files.empty?
    copy_files_to_dest(non_music_files)
  end

  if !music_files.empty?
    convert_files_to_dest(music_files)
  end

  if !@failed.empty?
    handle_errors(@failed)
  end

  teardown
  summary
end

main

