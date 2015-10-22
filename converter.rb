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



