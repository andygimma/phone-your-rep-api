# frozen_string_literal: true

namespace :pyr do
  namespace :zcta_districts do
    desc 'Export ZCTA district relationships to CSV'
    task :export do
      Dir.chdir(Rails.root.join('lib')) do
        File.open('zctas.txt', 'w') do |csv|
          csv.write ZctaDistrict.order(:zip_code).to_csv
        end

        File.open('zctas.json', 'w') do |json|
          json.write JSON.pretty_generate(
            CSV.open('zctas.txt', headers: true).map do |row|
              { zip: row['zip'], state: row['state'], district: row['district'] }
            end
          )
        end

        File.open('zctas.yaml', 'w') do |yaml|
          yaml.write JSON.parse(
            File.read('zctas.json')
          ).to_yaml
        end

        if Rails.env.development?
          puts `git add zctas.*; git commit -m 'update zcta index files'`
          puts `git push heroku master` if ENV['deploy'] == 'true'
        end
      end
    end

    desc 'Update ZCTA district data'
    task :update do
      ZctaDistrict.all.each do |zd|
        zd.zip_code      = zd.zcta.zcta
        zd.state         = zd.district.state.abbr
        zd.district_code = zd.district.code
        zd.save
        puts "Updated #{zd.zip_code} - #{zd.district.full_code}"
      end

      Rake::Task['pyr:zcta_districts:export'].invoke
    end
  end
end
