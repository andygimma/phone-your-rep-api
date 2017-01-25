require_relative '../config/environment.rb'

def import_geoms(dir:, shp_file:, model:, model_attr:, record_attr:)
  RGeo::Shapefile::Reader.open(Rails.root.join('lib', 'shapefiles', dir, shp_file).to_s, factory: model::FACTORY) do |file|
    puts "File contains #{file.num_records} records."
    file.each do |record|
      puts "Record number #{record.index}:"
      instance = model.find_by(model_attr => record.attributes[record_attr])
      instance.update(geom: record.geometry.projection)
      puts record.attributes
    end
  end
end

def import_districts(dir:, shp_file:, model:, model_attr:, record_attr:)
  RGeo::Shapefile::Reader.open(Rails.root.join('lib', 'shapefiles', dir, shp_file).to_s, factory: model::FACTORY) do |file|
    puts "File contains #{file.num_records} records."
    file.each do |record|
      puts "Record number #{record.index}:"
      record.geometry.projection.each do |poly|
        model.create(code: record.attributes['CD114FP'],
                     state_code: record.attributes['STATEFP'],
                     full_code: record.attributes['GEOID'],
                     geom: poly)
      end
      puts record.attributes
    end
  end
end

import_geoms(dir:         'us_states_122116',
             shp_file:    'cb_2015_us_state_500k.shp',
             model:       State,
             model_attr:  :state_code,
             record_attr: 'STATEFP')

import_districts(dir:         'us_congress_districts_122116',
                 shp_file:    'cb_2015_us_cd114_500k.shp',
                 model:       District,
                 model_attr:  :full_code,
                 record_attr: 'GEOID')
