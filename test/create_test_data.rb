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
# Script to mock Court's music directory structure so I can run tests locally.
#

require 'fileutils'

# Audio files in Court's music directory match the following regex pattern
PATTERN = /^(\._\d|_\d|\.d|\d)/

#
#
def create_path(path_to_create)
  path = path_to_create[0,1] == "/" ? "." + path_to_create : path_to_create
  path = path.chomp(":") if path[-1,1] == ":"

  FileUtils.mkdir_p(path)
  path
end

#
#
def create_file(path, file)
  puts(path + ":: " + file)
  FileUtils.touch(path + "/" + file)
end

#
#
def parse_contents(path, contents)
  # Split files and clean input
  files = contents.split(", ")
  files = files.drop(2) # Remove '.' and '..'
  files.select!{|f| !Dir.exists?(path + "/" + f)}

  # A bit of sloppy heuristics to reconstruct the file name
  processed = []
  last = nil

  files.each do |f|
    if PATTERN === f && f.include?(" ")
      processed << last if last
      last = f
    else
      last ? last += ", " + f : processed << f
    end
  end

  if last && (PATTERN === last || processed.last != last)
    processed << last
  end

  processed
end

#
#
def process_chunk(chunk)
  # We can rely on the following format for each chunk:
  #   chunk[0] = path
  #   chunk[1] = directory contents
  #   chunk[2] = newline
  path = chunk[0]
  contents = chunk[1]

  # 1. Create the path
  path = create_path(path)

  # 2. Parse contents into files
  files = parse_contents(path, contents)

  # 3. Create files
  files.each do |f|
    create_file(path, f)
  end
end

#
#
def create_test_data
  # This file contains Court's music directory dumped to a text file via:
  #   ls -Ram > music.txt
  #
  # Unfortunately, the text file doesn't really cleanly distinguish between 
  # directories and music files, however, subdirectories are always listed
  # after any parent directories, so we'll parse the file in reverse order
  # and hope for the best.
  file_name = "./music.txt"
  file = File.open(file_name, "r")

  data = file.read.each_line.to_a
  data.map!{|l| l.chomp("\r\n")}

  chunks = data.each_slice(3).to_a
  chunks.reverse!

  # Now recreate the directories and files
  chunks.each do |c|
    process_chunk(c)
  end

  file.close
end

#
#
create_test_data
