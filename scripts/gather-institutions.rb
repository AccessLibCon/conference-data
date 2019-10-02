#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'set'
require 'byebug'

master_institution_data = {}
# load existing institution data, if any
if File.exists?('../data/institutions.json')
  master_institution_data = JSON.parse(File.read('../data/institutions.json'))
end

puts 'Known institutions: ' + master_institution_data.keys.count.to_s

new_institutions = Set.new

Dir.glob('../csv/*.csv').sort.each do |csvfile|
  conference_data = CSV.read(csvfile, headers: :first_row).map(&:to_h)
  year = csvfile.gsub(/.*(\d{4}).*/, '\1')
  puts 'Year: ' + year

  conference_data.each do |paper|
    paper['speakers'].to_s.split(/\s*\|\s*/).each do |speaker|
      speaker = speaker.strip.gsub(/\s+/, ' ')
      parsed = speaker.match(/(.*) \((.*)\)/)
      name = ''
      institution = ''
      if parsed.nil?
        name = speaker
        institution = nil
      else
        name = parsed[1]
        institution = parsed[2]
      end
      # only gather institutions that are not already in institutions.json
      new_institutions << institution.strip if (institution and !master_institution_data.keys.include?(institution))
    end if paper['speakers']
  end
end

puts 'New institutions: ' + new_institutions.count.to_s

new_institutions.to_a.sort.each { |institution|
  master_institution_data[institution] = {city: nil, type: nil, ignore: false}
}

File.open("../data/institutions.json","w") do |f|
  f.write(JSON.pretty_generate(master_institution_data.sort.to_h))
end
