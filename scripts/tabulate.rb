#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'gender_detector'
require 'time'
require 'byebug'

@andyname = {
  'Danoosh' => 'male',
  'Ekatarina' => 'female',
  'Lelland' => 'male',
  'J.' => 'male',
  'Yoo' => 'female',
  'Weiwei' => 'female',
  'Whitni' => 'female',
  'Weina' => 'female',
  'Fangmin' => 'male',
  'Amaz' => 'male',
  'Channarong' => 'male',
  'Kaouther' => 'female',
  'Riel' => 'male',
  'Jer' => 'male',
  'MJ' => 'male',
  'Carell' => 'female',
  'Janneka' => 'female',
  'Catelynne' => 'female',
  'Jonathan' => 'male',
  'Su' => 'female',
  'Lorcan' => 'male',
  'Norm' => 'male',
  'Franceen' => 'female',
  'Selden' => 'male',
  'Murray' => 'male',
  'Arnald' => 'male'
}

newandy = []

@gd = GenderDetector.new

def getGender(name)
  gender = @gd.get_gender(name).to_s.gsub('mostly_', '')
  if gender == 'andy'
    gender = @andyname[name] if @andyname[name]
  end
  gender
end

# total data
data = {}
totaltypes = {'total' => 0}
totaldurations = {'total' => 0.0}
totalspeakers = {'none' => 0}
totalminutes = {'none' => 0.0}

CSV.open("../tabulation.csv", "w") do |csv|
  csv << ['year','total_count','total_duration',
  'talk_count','talk_duration',
  'keynote_count', 'keynote_duration',
  'lightning_count', 'lightning_duration',
  'report_count', 'report_duration',
  'ama_count', 'ama_duration',
  'bof_count', 'bof_duration',
  'panel_count', 'panel_duration',
  'poster_count', 'poster_duration',
  'binkley_count', 'binkley_duration',
  'female_count', 'female_duration',
  'male_count', 'male_duration',
  'andy_count', 'andy_duration'
]

  Dir.glob('../csv/*.csv').sort.each do |csvfile|
    input = CSV.read(csvfile, headers: :first_row).map(&:to_h)
    year = csvfile.gsub(/.*(\d{4}).*/, '\1')
    puts 'Year: ' + year
    
    gendercounts = {}
    genderdurations = {}
    typecounts = {'total' => 0}
    typedurations = {'total' => 0.0}

    # we assume times less than 8:00 are pm
    eightoclock = Time.parse('8:00')
    twelvehours = 12 * 60 * 60
    confduration = 0

    input.each do |row|
      times = row['time'].gsub(/[^0-9:]/, ' ').gsub(/\s+?/, ' ').strip.split(' ')
      start = Time.parse(times[0])
      finish = Time.parse(times[1])
      if start < eightoclock 
        start += twelvehours
      end
      if finish < eightoclock
        finish += twelvehours
      end
      duration = (finish - start) / 60
      confduration += duration
      totaldurations['total'] += duration
      #puts row['date'] + ' ' + row['time'] + ': ' + duration.to_s + ' minutes'

      typecounts['total'] += 1
      typedurations['total'] += duration
      totaltypes['total'] += 1
      totaldurations['total'] += duration

      if row['type'] != ''
        eventtypes = row['type'].to_s.split(/,\s?/)
        eventtypes.each do |type|
          typecounts[type] = 0 unless typecounts[type]
          typecounts[type] += 1
          typedurations[type] = 0 unless typedurations[type]
          typedurations[type] += duration
          totaltypes[type] = 0 unless totaltypes[type]
          totaltypes[type] += 1
          totaldurations[type] = 0 unless totaldurations[type]
          totaldurations[type] += duration
        end
      end 

      speakers = row['speakers'].to_s.split('|')
      if speakers[0] != ''
        speakers.each do |speaker|
          firstname = speaker.gsub(/(.+?)\ .*/, '\1').strip
          next unless firstname
          gender = getGender(firstname)
          newandy << firstname if gender == 'andy'
          gendercounts[gender] = 0 unless gendercounts[gender]
          gendercounts[gender] += 1
          totalspeakers[gender] = 0 unless totalspeakers[gender]
          totalspeakers[gender] += 1

          genderdurations[gender] = 0 unless genderdurations[gender]
          genderdurations[gender] += (duration / speakers.count)
          totalminutes[gender] = 0 unless totalminutes[gender]
          totalminutes[gender] += (duration / speakers.count)
          puts firstname + ': ' + gender + ' - ' + (duration / speakers.count).to_s + ' min'
        end
      else
        totalspeakers['none'] += 1
        totalminutes['none'] ++ duration
      end
    end

    output = 'Speakers: '

    gendercounts.keys.each do |key|
      output += (key + ': ' + gendercounts[key].to_s + ' | ')
    end

    puts output

    output = 'Time: '

    genderdurations.keys.each do |key|
      output += (key + ': ' + sprintf('%.1f', (genderdurations[key] / confduration * 100)) + '% | ')
    end

    puts output

    puts 'New andy names: ' + newandy.join(', ') if newandy.count > 0

    csv << [
      year,
      typecounts['total'],
      typedurations['total'],
      typecounts['talk'],
      typedurations['talk'],
      typecounts['keynote'],
      typedurations['keynote'],
      typecounts['lightning'],
      typedurations['lightning'],
      typecounts['report'],
      typedurations['report'],
      typecounts['ama'],
      typedurations['ama'],
      typecounts['bof'],
      typedurations['bof'],
      typecounts['panel'],
      typedurations['panel'],
      typecounts['poster'],
      typedurations['poster'],
      typecounts['binkley'],
      typedurations['binkley'],
      gendercounts['female'],
      genderdurations['female'],
      gendercounts['male'],
      genderdurations['male'],
      gendercounts['andy'],
      genderdurations['andy']
    ]
  end

  data['durations'] = totaldurations
  data['minutes'] = totalminutes
  data['types'] = totaltypes
  data['speakers'] = totalspeakers

  File.open("../test.json","w") do |f|
    f.write(JSON.pretty_generate(data))
  end

end
