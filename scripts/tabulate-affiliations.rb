#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'geocoder'
require 'descriptive_statistics'
require 'byebug'

Geocoder.configure(:units => :km)

institutions = JSON.parse(File.read('../data/institutions.json'))
places = JSON.parse(File.read('../data/places.json'))
mappings = JSON.parse(File.read('../data/mappings.json'))

confoutput = []
cities = {}
locations = []
distances = []

confcoords = [53.535411,-113.507996]

input = CSV.read('../data/2019-affiliations.csv', headers: :first_row).map(&:to_h)

input.each do |row|
  institution = row['affiliation']
  puts institution
  city = institutions[institution]['city'] if institutions[institution]
  place = places[mappings[city]]
  cities[city] = {
    'city' => city,
    'province' => place['country'] == 'Canada' ? place['state'] : '',
    'count' => 0,
    'distance' => (Geocoder::Calculations.distance_between(confcoords,[place['lat'], place['lon']]) * 1000).round,
    'lat' => place['lat'],
    'lon' => place['lon']
  } unless cities[city]
  cities[city]['count'] += 1

end

File.open("../2019-affiliations.json","w") do |f|
  f.write(JSON.pretty_generate(cities))
end

CSV.open("../affiliations-tabulation.csv", "w") do |csv|
  cities.keys.each do |key|
    city = cities[key]
    csv << [city['city'], city['state'], city['count'], city['distance'], city['lat'], city['lon'] ]
  end
end
