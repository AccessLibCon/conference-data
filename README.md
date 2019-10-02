The program data has been marshalled in a [Google Sheet](https://docs.google.com/spreadsheets/d/1nUCwHW76IUvRm8J3G77berE_8YTdEiVQs4YYYOO0smo/edit), with a worksheet for each conference (currently starting with 1996). The worksheets have been exported into the ```csv`` directory with names like ```1993.csv```. Until the data format is finalized, I've considered the Google Sheet to be the authoritative source and the csv files to be working derivatives. Therefore update the Google Sheet to make changes and download new csv files, until the decision is made to consider the csv files the authoritative source.

List of conferences and sources: [Access Conference History](https://docs.google.com/document/d/1HaLwFLtYF_7uaQQ3WBFXJhZnY3kMr3z7GdNhs0zFXAM/edit)

The only non-flat field in the csv is the speakers column, which can contain multiple speakers (pipe-separated). Individual speakers are listed in the form ```name (institution)```. Not all speakers have institutions. Institution names have not been normalized and many different forms (```University of Alberta```, ```U of Alberta```, ```University of Alberta Libraries``` etc.)

The schedule times are preserved, and are generally in the form ```19:00 - 10:00``` (with many variations), always in the 12-hour clock.


Geocoding of institutions is a complex chain: Non-normalized institution name from program is gathered into institutions.json by gather-institutions.rb;

instution.json entries look like this:

```
"Emory University, Atlanta, GA": {
    "city": "Atlanta",
    "type": null,
    "ignore": false
  },
```

The ```city``` property is added manually. It will be used for geocoding by ```gather-places.rb```, so it needs to be specific enough for a lookup. Big cities work (like ```Toronto```), smaller ones or ambiguious ones need more details (```Victoria, BC, Canada```)

Sample code for geocoding places:


```
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
```

Sample parsing of program times:

```
# we assume times less than 8:00 are pm
eightoclock = Time.parse('8:00')
twelvehours = 12 * 60 * 60

...

times = row['time'].gsub(/[^0-9:]/, ' ').gsub(/\s+?/, ' ').strip.split(' ')
start = Time.parse(times[0])
finish = Time.parse(times[1])

# convert pm times to 24 hour format
start += twelvehours if start < eightoclock
finish += twelvehours if finish < eightoclock

duration = (finish - start) / 60

```
