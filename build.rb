#!/usr/local/bin/ruby

require './config'

#In case gem path is not set
#require 'rubygems'
#Gem.path.push GEMS_PATH

require 'find'
require 'haml'
require 'bluecloth'

#for archive listing
$posts = []
$haml_engine = Haml::Engine.new(File.read("#{STATIC_DIR}/views/layout.haml"))

def generateTimestamp(path)
	f_ctime = File.stat(path).ctime.utc
	f_ctime += 19800 # +05:30 for IST
	f_ctime.strftime("last modified on %d %b %Y, %I:%M %p")
end

def renderPost(srcFile, destFile)
	# read the contents
	contents = File.read(srcFile)
	html = BlueCloth::new(contents).to_html

	# get the timestamp
	timestamp = generateTimestamp(srcFile)

	# render
	locals = {:content => html, :timestamp => timestamp}
	txt = $haml_engine.render(Object.new, locals)

	# and write it to the destination
	f = File.open(destFile, 'w')
	f.write(txt)
	f.close()

	# add to list
	$posts.push({:path => destFile, :timestamp => timestamp})
end

# generate the posts
Find.find(CONTENT_DIR) do |path|
	next if not(FileTest.file?(path) and (path =~ /\.md$/))

	filename = path.slice(CONTENT_DIR.length..-1)
	srcFile = "#{CONTENT_DIR}/#{filename}"
	destFile = "#{PUBLISH_DIR}/#{filename.gsub(/\.md$/, '.html')}"
	renderPost(srcFile, destFile)
end

# generate the archive
$posts.sort! { |x, y| y[:timestamp] <=> x[:timestamp] } # latest post first

f = File.open("#{CONTENT_DIR}/browse.tmp", 'w')
f.write("Archive\n---\n\n")
$posts.each do |post|
	url = post[:path].slice(PUBLISH_DIR.length..-1)
	url.gsub!(/^\/+/, '') # remove preceding /
	f.write("[#{url}](#{url}), at #{post[:timestamp]}\n")
end
f.close()
renderPost(f.path, "#{PUBLISH_DIR}/browse.htm") # .htm file won't conflict

# copy static files

