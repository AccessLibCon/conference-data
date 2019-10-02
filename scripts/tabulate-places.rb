#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'geocoder'
require 'descriptive_statistics'
require 'byebug'

Geocoder.configure(:units => :km)

conferences = {
  '1993' => 'Winnipeg',
  '1994' => 'St. John\'s',
  '1995' => 'Fredericton',
  '1996' => 'Vancouver',
  '1997' => 'Calgary',
  '1998' => 'Saskatoon',
  '1999' => 'Guelph',
  '2000' => 'St. John\'s',
  '2001' => 'Winnipeg',
  '2002' => 'Windsor',
  '2003' => 'Vancouver',
  '2004' => 'Halifax',
  '2005' => 'Edmonton',
  '2006' => 'Ottawa',
  '2007' => 'Victoria',
  '2008' => 'Hamilton',
  '2009' => 'Charlottetown',
  '2010' => 'Winnipeg',
  '2011' => 'Vancouver',
  '2012' => 'Montreal',
  '2013' => 'St. John\'s',
  '2014' => 'Calgary',
  '2015' => 'Toronto',
  '2016' => 'Fredericton',
  '2017' => 'Saskatoon',
  '2018' => 'Hamilton',
  '2019' => 'Edmonton'
}
institutions = JSON.parse(File.read('../data/institutions.json'))
places = JSON.parse(File.read('../data/places.json'))
mappings = JSON.parse(File.read('../data/mappings.json'))

confoutput = []

CSV.open("../place-tabulation.csv", "w") do |csv|
  csv << ['year', 'Canada', 'USA', 'other', 'ave_distance']
  Dir.glob('../csv/*.csv').sort.each do |csvfile|
    input = CSV.read(csvfile, headers: :first_row).map(&:to_h)
    year = csvfile.gsub(/.*(\d{4}).*/, '\1')

    location = places[mappings[conferences[year]]]
    confcoords = [location['lat'], location['lon']]

    puts 'Year: ' + year + ' ' + conferences[year]
    
    conf = {'year' => year, 'Canada' => 0, 'USA' => 0, 'other' => 0}
    distances = []
    input.each do |row|
      speakers = row['speakers'].to_s.split('|')
      if speakers[0] != ''
        speakers.each do |speaker|
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
          city = institutions[institution]['city'] if institutions[institution]
          if city
            place = places[mappings[city]]
            country = place['country']
            country = 'USA' if country == 'United States of America'
            if country == 'Canada'
              conf['Canada'] += 1
            elsif country == 'USA'
              conf['USA'] += 1
            else
              conf['other'] += 1
            end
            distances << (Geocoder::Calculations.distance_between(confcoords,[place['lat'], place['lon']]) * 1000).round
          end
        end
      end
    end
    csv << [year, conf['Canada'], conf['USA'], conf['other'], distances.mean.round]
    confoutput << [year, conferences[year], '', '', confcoords[0], confcoords[1], distances.mean.round]
  end
end

File.open("../conflocations.json","w") do |f|
  f.write(JSON.pretty_generate(confoutput))
end
