#!/usr/bin/ruby
##
#
# Half-assed Ruby script that copies all the pretty Windows spotlight images to
# a separate directory.
#
# This was never actually tested on windows, but it *should* work.
#

require 'fileutils'
require 'digest'
require 'date'
require 'exifr/jpeg'

# Only used in Linux mode
username = ARGV[0]
source = ARGV[1]

ASSET_DIR = 'AppData/Local/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets'.freeze

def categorise(image)
  width = get_width(image)

  case width
  when 1920
    'desktop'
  when 1080
    'mobile'
  end
end

def get_width(file)
  exif = EXIFR::JPEG.new(file)
  exif.width
rescue EXIFR::MalformedJPEG
  nil
end

def are_equal(file1, file2)
  Digest::SHA256.file(file1) == Digest::SHA256.file(file2)
end


case RbConfig::CONFIG['host_os']
when /linux/
  if ARGV.length < 2
    warn 'On linux you need to provide the username and source (partition, or mount point of Windows installation) to steal from.'
    warn 'For example:'
    warn '  steal.rb nino /dev/nvme1n1p4'
    exit 1
  end

  source_stat = File.stat(source)

  if source_stat.blockdev?
    mount_result = `udisksctl mount -t ntfs -o ro -b #{source}`
    puts mount_result

    match = mount_result.match(%r{Mounted #{source} at (\/run\/media\/#{ENV['USER']}\/\w+)\.$})

    if match
      prefix = match[1]
      at_exit { puts `udisksctl unmount -b #{source}` }
    else
      warn "Error mounting #{source}"
      exit 2
    end

  else
    prefix = source
  end

  SRC = "#{prefix}/Users/#{username}/#{ASSET_DIR}".freeze
  DEST = (ENV['SPOTLIGHT_DEST'] || "#{ENV['HOME']}/Pictures/Spotlight").freeze
else
  SRC =  "#{ENV['HOMEPATH']}/#{ASSET_DIR}".freeze
  DEST = (ENV['SPOTLIGHT_DEST'] || "#{ENV['HOMEPATH']}/Pictures/Spotlight").freeze
end

puts "SRC: #{SRC}"
puts "DEST: #{DEST}"

# Create DEST dir
FileUtils.mkdir_p DEST
FileUtils.mkdir_p File.join(DEST, 'desktop')
FileUtils.mkdir_p File.join(DEST, 'mobile')
FileUtils.mkdir_p File.join(DEST, 'other')

files = Dir.entries(SRC).reject { |f| File.directory? f }

print 'Stealing'
files.each do |file|
  src = File.join(SRC, file)
  category = categorise(src)

  next if category.nil?

  dest = File.join(DEST, category, "#{file}.jpg")

  if File.exist?(dest)
    if are_equal(src, dest)
      print '.'
      next
    end

    print '!'
    dest = File.join(DEST, category, "#{file}-#{Date.today}.jpg")
  end

  FileUtils.copy(src, dest)
  print '+'
end

puts
