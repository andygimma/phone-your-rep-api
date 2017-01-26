# Phone Your Rep API

WIP.
The companion to [the Phone Your Rep frontend](https://github.com/kylebutts/phone_your_rep).

Data sources:

Congress - https://github.com/TheWalkers/congress-legislators

State and district shapefiles - https://www.census.gov/geo/maps-data/data/tiger-cart-boundary.html

# Vagrant
If you are too busy to do the manual installation, you can download a Vagrant BOX which has the requirements below already installed, download it here.

https://s3.amazonaws.com/debugpyr/pyr.box

# Installation

Be sure to use Ruby 2.3.3.

```
rbenv install 2.3.3 or rvm install 2.3.3
```

```
brew install postgres
brew install postgis
```

Or download the [Heroku PostgreSQL app](https://postgresapp.com/) and forgo the brew postgres and postgis install. This is by far the easiest route.

Then

```
gem install rails --no-ri --no-rdoc
gem install bundler
bundle install
```
You can setup and then fully seed the database with one rake task:
```
bundle exec rake pyr_db_setup
```
If you've already configured the database before, and are just resetting or updating, it's recommended that you just rake. It might take a few, so grab a cold one. If you're configuring for the first time, and/or you're getting errors, or you don't want to do a complete reset, or for whatever reason you just want more control, here are the manual steps:
```
rails db:create
rails db:gis:setup
rails db:migrate
```
Migrating is your first test that you have a properly configured database. If you get errors while migrating, you may have PostGIS configuration issues and your database is not recognizing the geospatial datatypes. Read up on the documentation for RGeo and ActiveRecord PostGIS Adapter to troubleshoot.
#####Seeding the data
Many of the offices have coordinates preloaded in the seed data. Any that don't will automatically be geocoded during seeding.

The `geocoder` gem allows you to do some geocoding without an API key. It will probably be enough for development. However, if you want to use your own API key for geocoding, you can configure it in `config/initializers/geocoder.rb`. You will also need to check this file for deployment, as it's configured to access an environment variable for the API key in production.

If you don't want to geocode any of the offices at all, comment out this line in office_location.rb
```ruby
after_validation :geocode, if: :needs_geocoding?
```
Then seed the db
```
bundle exec rake db:seed
```
When you're done seeding the basic data, you need to load the shapefiles for district and state geometries. This is the final test that your database is properly configured. Run
```
ruby lib/shapefiles.rb
```
Then add photo URLs to the reps
```
ruby lib/add_photots.rb
```
and generate V-cards for every office location
```
ruby lib/add_v_cards.rb
```
and load up the QR code URL data, to access the publicQR code images stored on the S3 server
```
ruby lib/import_qr_codes.rb
```
Finally
```
rails s
```
If you want to generate your own QR codes for the office locations, drop into the console with `rails c` and enter this line
```ruby
OfficeLocation.all.each { |office| office.add_qr_code_img }
```
And change `OfficeLocation#qr_code_link` to
```ruby
def qr_code_link
    return if qr_code.blank?
    if Rails.env.production?
      "https://s3.amazonaws.com/phone-your-rep-images/#{qr_code_uid.split('/').last}" if qr_code_uid
    elsif Rails.env.development?
      "http://localhost:3000#{qr_code.url}"
    end
  end
```
QR code generation is a pretty long process, and in most cases is not necessary unless the public images are inaccurate. Feel free to skip it.

This is deployed on Heroku. Deploying a geo-spatially enabled database to Heroku can be a bit of a challenge. Docs for that will come soon.

#Usage
This API is in beta. An example request to the API looks like this:
```
https://phone-your-rep.herokuapp.com/api/beta/reps?lat=42.3134848&long=-71.2072321
```

And here is the response:
```json
[
  {
    "bioguide_id": "K000379",
    "official_full": "Joseph P. Kennedy III",
    "state": "MA",
    "district": "04",
    "role": "United States Representative",
    "party": "Democrat",
    "senate_class": null,
    "last": "Kennedy",
    "first": "Joseph",
    "middle": "P.",
    "nickname": null,
    "suffix": "III",
    "contact_form": null,
    "url": "https://kennedy.house.gov",
    "photo": "https://theunitedstates.io/images/congress/450x550/K000379.jpg",
    "twitter": "RepJoeKennedy",
    "facebook": "301936109927957",
    "youtube": null,
    "instagram": "repkennedy",
    "googleplus": null,
    "twitter_id": "1055907624",
    "facebook_id": "301936109927957",
    "youtube_id": "UCgfHlaGqxD8p-2V_YlNIqrA",
    "instagram_id": "1328567154",
    "office_locations": [
      {
        "office_id": 1200,
        "type": "district",
        "distance": 2.9,
        "building": "",
        "address": "29 Crafts St.",
        "suite": "Suite 375",
        "city": "Newton",
        "state": "MA",
        "zip": "02458",
        "phone": "617-332-3333",
        "fax": "617-332-3308",
        "hours": "M-F 9-5:30PM",
        "latitude": 42.3548224,
        "longitude": -71.1999166,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1200",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/7gubdgo2kr_Kennedy_district_1200.png"
      },
      {
        "office_id": 1199,
        "type": "district",
        "distance": 25.8,
        "building": "",
        "address": "8 N. Main St.",
        "suite": "Suite 200",
        "city": "Attleboro",
        "state": "MA",
        "zip": "02703",
        "phone": "508-431-1110",
        "fax": "508-431-1101",
        "hours": "M-F 9-5:30PM",
        "latitude": 41.9449626,
        "longitude": -71.2846799,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1199",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/3yratflx0b_Kennedy_district_1199.png"
      },
      {
        "office_id": 368,
        "type": "capitol",
        "distance": 385.4,
        "building": null,
        "address": "434 Cannon HOB",
        "suite": null,
        "city": "Washington",
        "state": "DC",
        "zip": "20515-2104",
        "phone": "202-225-5931",
        "fax": null,
        "hours": null,
        "latitude": 38.8870943,
        "longitude": -77.0082254,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/368",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/62qf7ihqu3_Kennedy_capitol_368.png"
      }
    ]
  },
  {
    "bioguide_id": "W000817",
    "official_full": "Elizabeth Warren",
    "state": "MA",
    "district": null,
    "role": "United States Senator",
    "party": "Democrat",
    "senate_class": "01",
    "last": "Warren",
    "first": "Elizabeth",
    "middle": null,
    "nickname": null,
    "suffix": null,
    "contact_form": "http://www.warren.senate.gov/?p=email_senator#thisForm",
    "url": "http://www.warren.senate.gov",
    "photo": "https://theunitedstates.io/images/congress/450x550/W000817.jpg",
    "twitter": "SenWarren",
    "facebook": "senatorelizabethwarren",
    "youtube": "senelizabethwarren",
    "instagram": null,
    "googleplus": null,
    "twitter_id": "970207298",
    "facebook_id": "131559043673264",
    "youtube_id": "UCTH9zV8Imw09J5bOoTR18_A",
    "instagram_id": null,
    "office_locations": [
      {
        "office_id": 1897,
        "type": "district",
        "distance": 8.2,
        "building": "2400 JFK Federal Building",
        "address": "15 Sudbury St.",
        "suite": "",
        "city": "Boston",
        "state": "MA",
        "zip": "02203",
        "phone": "617-565-3170",
        "fax": "",
        "hours": "",
        "latitude": 42.3613091,
        "longitude": -71.0593927,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1897",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/9g9zrqnpbu_Warren_district_1897.png"
      },
      {
        "office_id": 1898,
        "type": "district",
        "distance": 72.4,
        "building": "",
        "address": "1550 Main St.",
        "suite": "Suite 406",
        "city": "Springfield",
        "state": "MA",
        "zip": "01103",
        "phone": "413-788-2690",
        "fax": "",
        "hours": "",
        "latitude": 42.1032165,
        "longitude": -72.5929441,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1898",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/61252tqznk_Warren_district_1898.png"
      },
      {
        "office_id": 367,
        "type": "capitol",
        "distance": 385.0,
        "building": null,
        "address": "317 Hart Senate Office Building",
        "suite": null,
        "city": "Washington",
        "state": "DC",
        "zip": "20510",
        "phone": "202-224-4543",
        "fax": null,
        "hours": null,
        "latitude": 38.8928318,
        "longitude": -77.0043625,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/367",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/4cb6hk2egn_Warren_capitol_367.png"
      }
    ]
  },
  {
    "bioguide_id": "M000133",
    "official_full": "Edward J. Markey",
    "state": "MA",
    "district": null,
    "role": "United States Senator",
    "party": "Democrat",
    "senate_class": "02",
    "last": "Markey",
    "first": "Edward",
    "middle": "J.",
    "nickname": "Ed",
    "suffix": null,
    "contact_form": "http://www.markey.senate.gov/contact",
    "url": "http://www.markey.senate.gov",
    "photo": "https://theunitedstates.io/images/congress/450x550/M000133.jpg",
    "twitter": "SenMarkey",
    "facebook": "EdJMarkey",
    "youtube": "RepMarkey",
    "instagram": null,
    "googleplus": null,
    "twitter_id": "3047090620",
    "facebook_id": "6846731378",
    "youtube_id": "UCT1ujew5yQy2uMhGrjiKHoA",
    "instagram_id": null,
    "office_locations": [
      {
        "office_id": 1314,
        "type": "district",
        "distance": 8.2,
        "building": "975 JFK Federal Building",
        "address": "15 Sudbury St.",
        "suite": "",
        "city": "Boston",
        "state": "MA",
        "zip": "02203",
        "phone": "617-565-8519",
        "fax": "",
        "hours": "",
        "latitude": 42.3613091,
        "longitude": -71.0593927,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1314",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/9o6tqptj1_Markey_district_1314.png"
      },
      {
        "office_id": 1315,
        "type": "district",
        "distance": 42.5,
        "building": "",
        "address": "222 Milliken Blvd.",
        "suite": "Suite 312",
        "city": "Fall River",
        "state": "MA",
        "zip": "02721",
        "phone": "508-677-0523",
        "fax": "",
        "hours": "",
        "latitude": 41.6999176,
        "longitude": -71.1587266,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1315",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/3c4hp2pyzd_Markey_district_1315.png"
      },
      {
        "office_id": 1316,
        "type": "district",
        "distance": 72.4,
        "building": "",
        "address": "1550 Main St.",
        "suite": "4th Floor",
        "city": "Springfield",
        "state": "MA",
        "zip": "01101",
        "phone": "413-785-4610",
        "fax": "",
        "hours": "",
        "latitude": 42.1032165,
        "longitude": -72.5929441,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/1316",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/77buuaccxv_Markey_district_1316.png"
      },
      {
        "office_id": 200,
        "type": "capitol",
        "distance": 385.0,
        "building": null,
        "address": "255 Dirksen Senate Office Building",
        "suite": null,
        "city": "Washington",
        "state": "DC",
        "zip": "20510",
        "phone": "202-224-2742",
        "fax": null,
        "hours": null,
        "latitude": 38.8928318,
        "longitude": -77.0043625,
        "v_card_link": "https://phone-your-rep.herokuapp.com/v_cards/200",
        "qr_code_link": "https://s3.amazonaws.com/phone-your-rep-images/5puc375jgq_Markey_capitol_200.png"
      }
    ]
  }
]
```