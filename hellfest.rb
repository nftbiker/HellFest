#!/usr/bin/env ruby
# encoding: utf-8
# Usage: hell2025 folder_name
# Summary: analyze md files of the hellfest 2025 forum lineup and convert it to a big json

require "json"

def parse_markdown(file_path)
  groups = []
  current_group = nil

  File.foreach(file_path) do |line|
    if line.start_with?("## ")
      if current_group && current_group[:name] && current_group[:links]
        current_group[:links].uniq!
        current_group[:description] = current_group[:description].strip
        groups << current_group
      end
      current_group = { name: line.strip[3..] }
    elsif !current_group
      next
    elsif line.include?('<a href="')
      links = line.scan(/<a href="(.*?)"/).collect { |e| e[0] }.compact
      current_group[:links] = (current_group[:links] || []).concat(links)
    elsif line.include?("FFO :")
      current_group[:similars] = line.strip.gsub(/^[^:]+:/, "").strip.split(/[,;]+/im).map(&:strip)
    elsif line.include?("<td>")
      genre, country, _ = line.scan(/<td>(.*?)<\/td>/).flatten
      current_group[:genre] = genre.strip
      current_group[:country] = country.strip
    elsif line.empty? || line.match("___")
      next
    elsif !line.match(/https?:\/\/forum/)
      current_group[:description] ||= ""
      current_group[:description] << line
    end
  end
  groups << current_group if current_group

  groups
end

def generate_json(groups, output_file)
  File.open(output_file, "w") do |file|
    file.write(JSON.pretty_generate(groups: groups))
  end
end

dirname = ARGV[0] || "2025"

groups = []
Dir.glob(File.join("./src", dirname, "*.md")).each do |filename|
  groups.concat(parse_markdown(filename))
end
name = File.basename(dirname, ".*") + ".json"
generate_json(groups, File.join("./json", name))
