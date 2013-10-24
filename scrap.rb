require 'mechanize'
require 'awesome_print'

start_url = "http://indonesia.travel/en/destination/search/"
page = Mechanize.new.get(start_url)
@base_uri = page.uri

def clean(string)
	string.gsub(/\n/, "").strip
end

def section_parser(section)
	state = section.at_css "h2.section-title"
	ap state.content
	details = {}
	section.css(".en-detail").each do |detail|
		title = detail.at_css("h3").content
		info = detail.css("p").map(&:content).join
		details.merge!({title => info})
	end
	ap details
end

def poi_list(destination_list=nil, url=nil, states)
	current_list = []
	if url
		destination_list = Mechanize.new.get(url).parser.at_css("#whitecontent .content #destination_lists")
	end

	destination_list.css(".en-list").each do |d|
		data = { 
			poi_states: states,
			poi_name: clean(d.at_css(".en-desc-list a").content),
			poi_url: d.at_css(".en-desc-list a")[:href],
			poi_thumb: d.at_css("img")[:src]
		}
		ap data
		current_list << data
	end
	current_list
end

def destination_parser(destination_list, states)
	next_link = destination_list.css(".pagination a").map{|m| m[:href] }.uniq
	pois = poi_list destination_list, nil, states
	next_link.each do |link|
		pois += poi_list nil, @base_uri.merge(link), states
	end
end

def first_level(url, states)
	page1 = Mechanize.new.get url
	html1 = page1.parser
	# section = html1.at_css("#whitecontent .content .section")
	# section_parser section
	destination_list = html1.at_css("#whitecontent .content #destination_lists")
	destination_parser destination_list, states
end

html = page.parser
html.css("div.left_area a").each do |link|
	first_level link[:href], link.content
end



