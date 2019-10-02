#!/usr/bin/env ruby

require 'json'
require 'set'
require 'geocoder'
require 'byebug'

Geocoder.configure(:timeout => 30)

master_place_data = {}
# load existing place data, if any
if File.exists?('../data/places.json')
  master_place_data = JSON.parse(File.read('../data/places.json'))
end

puts 'Known places: ' + master_place_data.keys.count.to_s

mappings = {}
if File.exists?('../data/mappings.json')
  mappings = JSON.parse(File.read('../data/mappings.json'))
end
puts 'Mappings: ' + mappings.keys.count.to_s

new_places = Set.new

source = 'data/institutions.json'
# map city names from institutions to addresses from OpenStreetmap

file = '../' + source
source_data = JSON.parse(File.read(file))
puts 'Source: ' + file
source_data.keys.each do |key|
  if !source_data[key]['city'].nil?
    if !source_data[key]['address']
      s = source_data[key]
      if mappings.keys.include?(s['city'])
        s['address'] = mappings[s['city']]
      else
        result = Geocoder.search(s['city']).first
        puts 'Not found: ' + s['city'] if !result
        next if !result
        new = {
          address: result.address,
          city: (result.city.nil? ? '' : result.city),
          state: result.state,
          country: result.country,
          lat: result.coordinates[0],
          lon: result.coordinates[1],
        }
        mappings[s['city']] = result.address
        new_places << new[:city]
        
        master_place_data[result.address] = new
        puts s['city'] + ': ' + result.address
      end
    end
  end
end

puts 'New places: ' + new_places.count.to_s


File.open("../data/places.json","w") do |f|
  f.write(JSON.pretty_generate(master_place_data))
end

File.open("../data/mappings.json","w") do |f|
  f.write(JSON.pretty_generate(mappings))
end
