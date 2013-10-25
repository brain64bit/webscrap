require 'mechanize'
require 'awesome_print'

start_url = "http://indonesia.travel/en/destination/search/"
@agent = Mechanize.new
page = @agent.get(start_url)
@base_uri = page.uri

def clean(string)
	string.gsub(/\n/, "").strip
end

def asset_download(asset_url, new_name)
	`wget #{asset_url} -O #{new_name}`
end

page.links_with(href:/indonesia.travel\/en\/discover-indonesia\/region-detail\//).uniq(&:text).each do |link|
	state = link.text
	current_page, current_page_number = link.click, 1
	loop do
		current_page.search(".en-list").each do |tpoi|
			data = {
				poi_states: state,
				poi_name: clean(tpoi.at_css(".en-desc-list a").content),
				poi_url: tpoi.at_css(".en-desc-list a")[:href],
				poi_thumb: tpoi.at_css("img")[:src]
			}
			# puts tpoi.link_with(text:)
			puts data[:poi_url]
			detail = @agent.get(data[:poi_url])
			image_assets = detail.links_with(href:/indonesia.travel\/public\/media\/images\/upload\/poi\/\w/)
			data[:image_assets] = image_assets.map{|s| s.href }
			information = {}
			detail.search(".story").each do |d|
				title = d.at_css("h2").content
				puts title
				puts d.at_css(".fulltext")
				information.merge!({ title => d.at_css(".fulltext").try(:content) })
			end
			data[:information] = information
			ap data
		end
		current_page_number += 1
		next_link = current_page.link_with(text:"#{current_page_number}")
		break unless next_link != nil
		current_page = next_link.click
	end
end