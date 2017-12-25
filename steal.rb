#!/usr/bin/ruby
##
#
# Half-assed Ruby script that copies all the pretty Windows spotlight images to
# a separate directory.
#
# This was never actually tested on windows, but it *should* work.
#

require 'fileutils'
require 'exifr/jpeg'

# Only used in Linux mode
username = ARGV[0]
source = ARGV[1]

case RbConfig::CONFIG["host_os"]
when /linux/

  if ARGV.length < 2
    $stderr.puts "On linux you need to provide the username and source (partition, or mount point of Windows installation) to steal from."
    $stderr.puts "For example:"
    $stderr.puts "    steal.rb nino /dev/nvme1n1p4"
    exit 1
  end

  source_stat = File.stat(source)

  if source_stat.blockdev?
    mount_result = %x(udisksctl mount -t ntfs -o ro -b #{source})
    puts mount_result

    match = mount_result.match(/Mounted #{source} at (\/run\/media\/#{ENV['USER']}\/\w+)\.$/)

    if match
        prefix = match[1]
        at_exit { puts %x( udisksctl unmount -b #{source} ) }
    else
      $stderr.puts "Error mounting #{source}"
      exit 2
    end

  else
    prefix = source
  end


  SRC = "#{prefix}/Users/#{username}/AppData/Local/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets"
  DEST = ENV['SPOTLIGHT_DEST'] || "#{ENV['HOME']}/Pictures/Spotlight"
else
  username = ENV['USERNAME']
  SRC =  "#{ENV['HOMEPATH']}/AppData/Local/Packages/Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy/LocalState/Assets"
  DEST = ENV['SPOTLIGHT_DEST'] || "#{ENV['HOMEPATH']}/Pictures/Spotlight"
end

puts "SRC: #{SRC}"
puts "DEST: #{DEST}"

# Create DEST dir
FileUtils.mkdir_p DEST
FileUtils.mkdir_p File.join(DEST, "desktop")
FileUtils.mkdir_p File.join(DEST, "mobile")
FileUtils.mkdir_p File.join(DEST, "other")

files = Dir.entries(SRC)[2..-1]

def qualify_destination_path(path, dest)
    exif = EXIFR::JPEG.new(path)
    final_name = File.basename(path) + '.jpg'

    case(exif.width)
    when 1920
        return File.join(dest, "desktop", final_name)
    when 1080
        return File.join(dest, "mobile", final_name)
    else
        # return File.join(dest, "other", final_name)
        return nil
    end
rescue EXIFR::MalformedJPEG => e
    # puts "#{path} is not a valid JPG file"
    return nil
end

print 'Stealing'
files.each do |file|
    sp = File.join(SRC, file)
    dp = qualify_destination_path(sp, DEST)
    FileUtils.copy(sp, dp) unless dp.nil?
    print '.'
end

puts
