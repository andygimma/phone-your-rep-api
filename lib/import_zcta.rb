# frozen_string_literal: true
require 'csv'
require_relative '../config/environment.rb'

class ImportZCTA
  attr_reader :files

  def initialize(files = [])
    @files = files
  end

  def zcta_code(row)
    zcta5 = row['ZCTA5']
    case zcta5.size
    when 4
      '0' + zcta5
    when 3
      '00' + zcta5
    when 2
      '000' + zcta5
    else
      zcta5
    end
  end

  def seed_from_csv(file)
    csv_zcta_text = File.read(file)
    csv_zctas     = CSV.parse(csv_zcta_text, headers: true, encoding: 'ISO-8859-1')
    csv_zctas.each { |row| import_row(row) }
  end

  def import_row(row)
    state_code = row['STATE'].size == 1 ? '0' + row['STATE'] : row['STATE']
    dis_cod    = row['CD'].size == 1 ? '0' + row['CD'] : row['CD']
    zcta_code  = zcta_code(row)
    district   = District.find_by(full_code: state_code + dis_cod)
    zcta       = Zcta.where(zcta: zcta_code).first_or_create
    add_district(district, zcta, zcta_code) unless district.blank?
  end

  def add_district(district, zcta, zcta_code)
    zcta.districts << district
    puts "Added district #{district.code} to ZCTA #{zcta_code}"
  end

  def seed_all
    files.each { |file| seed_from_csv(file) }
  end
end

Zcta.destroy_all

import_zcta = ImportZCTA.new Dir[Rails.root.join('lib', 'seeds', 'zcta_cd', '*')]
import_zcta.seed_all

puts "There are now #{Zcta.count} ZCTAs in the database."
