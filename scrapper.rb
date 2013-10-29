require 'mechanize'
require 'awesome_print'
require 'json'
require 'active_support/core_ext'

start_url = "http://indonesia.travel/en/destination/search/"
@agent = Mechanize.new
page = @agent.get(start_url)
@base_uri = page.uri

def clean(string)
	string.gsub(/\n/, "").strip
end

def parameterize(string)
	string.downcase.gsub(" ", "_")
end

def asset_download(asset_url, new_name)
	extension = File.extname(asset_url)
	asset_uri = URI.escape(asset_url).gsub("(","%28").gsub(")", "%29")
	`wget #{asset_uri} -O #{new_name}#{extension} -q`
end

def json_dump(data)
	unless File.exist?("#{data[:id]}.json")
		name = "#{data[:id]}-#{parameterize(data[:poi_states])}"
		File.open("#{name}.json", "w") do |f|
			f.write(JSON.pretty_generate(data))
		end

		#download assets
		unless Dir.exist?("#{data[:id]}")
			Dir.mkdir("#{data[:id]}")
			Dir.chdir("#{data[:id]}")
			i = 1
			data[:image_assets].each do |path|
				asset_download path, i
				i += 1
			end
			Dir.chdir("..")
		end

		# ap data
		puts name
	end
end
poi_number = 1
page.links_with(href:/indonesia.travel\/en\/discover-indonesia\/region-detail\//).uniq(&:text).each do |link|
	state = link.text
	current_page, current_page_number = link.click, 1
	loop do
		current_page.search(".en-list").each do |tpoi|
			data = {
				id: poi_number,
				poi_states: state.strip,
				poi_name: clean(tpoi.at_css(".en-desc-list a").content),
				poi_url: tpoi.at_css(".en-desc-list a")[:href],
				poi_thumb: tpoi.at_css("img")[:src]
			}
			detail = @agent.get(data[:poi_url])
			image_assets = detail.links_with(href:/indonesia.travel\/public\/media\/images\/upload\/poi\/\w/)
			data[:image_assets] = image_assets.map{|s| s.href }
			information = {}
			detail.search(".story").select{|g| !(g.at_css("img") && g.at_css("img")[:src] =~ /maps.google.com/) }.each do |d|
				title = d.at_css("h2").content
				text = clean(d.at_css(".fulltext").content) rescue ""
				information.merge!({ parameterize(title) => text })
			end

			map_url = detail.parser.at_css(".story.img_map img")[:src] rescue nil
			unless map_url.blank?
				latlon = CGI.parse(URI.parse(map_url).query)["center"].first.split(",") rescue nil
				data[:poi_lat], data[:poi_lon] = latlon.map(&:to_f) if latlon.present?
			end

			data[:information] = information
			json_dump data
			poi_number += 1
		end
		current_page_number += 1
		next_link = current_page.link_with(text:"#{current_page_number}")
		break unless next_link != nil
		current_page = next_link.click
	end
end
