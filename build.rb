#!/usr/local/bin/ruby

require './config'

#In case gem path is not set
#require 'rubygems'
#Gem.path.push GEMS_PATH

require 'haml'
require 'bluecloth'

def render(content, timestamp, destFile)
	template = File.read(STATIC_DIR + '/views/layout.haml') # optimize, my foot
	haml_engine = Haml::Engine.new(template)
	txt = haml_engine.render(Object.new, {:content => content, :timestamp => timestamp})

	# and write it to the destination
	f = File.open(destFile, 'w')
	f.write(txt)
	f.close()
end

md_filenames = Dir.new(CONTENT_DIR).entries.select { |f| f =~ /\.md$/ }

md_filenames.each do |filename|
	f = "#{CONTENT_DIR}/#{filename}"
	contents = File.read(f)
	html = BlueCloth::new(contents).to_html

	publish_filename = /^(.*)\.md$/.match(filename)[1] + '.html'
	f_ctime = File.stat(f).ctime.utc + 19800 # +05:30 for IST
	timestamp = f_ctime.strftime("last modified on %d %b %Y, %I:%M %p")

	render(html, timestamp, "#{PUBLISH_DIR}/#{publish_filename}")
end

