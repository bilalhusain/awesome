#!/usr/local/bin/ruby

require './config'

#In case gem path is not set
#require 'rubygems'
#Gem.path.push GEMS_PATH

require 'find'
require 'haml'
require 'bluecloth'
require 'fileutils'

#for archive listing
$posts = []
$haml_engine = Haml::Engine.new(File.read("#{STATIC_DIR}/views/layout.haml"))

def generateTimestamp(path)
	f_ctime = File.stat(path).ctime.utc
	f_ctime += 19800 # +05:30 for IST
	f_ctime.strftime("%d %b %Y, %I:%M %p")
end

def renderPost(srcFile, destFile)
	# read the contents
	contents = File.read(srcFile)
	html = BlueCloth::new(contents).to_html

	# get the timestamp
	timestamp = generateTimestamp(srcFile)

	# render
	locals = {:content => html, :timestamp => "last modified on #{timestamp}"}
	txt = $haml_engine.render(Object.new, locals)

	# and write it to the destination
	f = File.open(destFile, 'w')
	f.write(txt)
	f.close()

	# add to list
	$posts.push({:path => destFile, :timestamp => timestamp})
end

# 1. copy static files
FileUtils.mkdir_p "#{PUBLISH_DIR}/static/"

FileUtils.cp_r "#{STATIC_DIR}/css", "#{PUBLISH_DIR}/static"
FileUtils.cp_r "#{STATIC_DIR}/images", "#{PUBLISH_DIR}/static"

# 2. generate the posts
Find.find(CONTENT_DIR) do |path|
	next if not(FileTest.file?(path) and (path =~ /\.md$/))

	filename = path.slice(CONTENT_DIR.length..-1)
	srcFile = "#{CONTENT_DIR}/#{filename}"
	destFile = "#{PUBLISH_DIR}/#{filename.gsub(/\.md$/, '.html')}"
	renderPost(srcFile, destFile)
end

# 3. generate the archive
$posts.sort! { |x, y| y[:timestamp] <=> x[:timestamp] } # latest post first

f = File.open("#{CONTENT_DIR}/browse.tmp", 'w')
f.write("Archive\n---\n\n")
$posts.each do |post|
	url = post[:path].slice(PUBLISH_DIR.length..-1)
	url.gsub!(/^\/+/, '') # remove preceding /
	f.write("* [#{url}](#{url}), at #{post[:timestamp]}\n")
end
f.close()
renderPost(f.path, "#{PUBLISH_DIR}/browse.htm") # .htm file won't conflict

# 4. setup index page
latest_post_path = nil # latest post is frontpage
latest_post_path = $posts[0][:path] if $posts.length > 0
FileUtils.cp latest_post_path, "#{PUBLISH_DIR}/index.htm" if latest_post_path

