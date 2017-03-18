# frozen_string_literal: true
require 'csv'
require_relative '../config/environment.rb'

def export_qr_codes
  offices = OfficeLocation.where(active: true)
  header = %w(id qr_code_uid qr_code_name)
  file = Rails.root.join('lib', 'qr_codes.csv').to_s
  CSV.open(file, 'wb') do |csv|
    csv << header
    offices.each do |o|
      csv << [o.office_id, o.qr_code_uid, o.qr_code_name]
      puts 'exported'
    end
  end
end

export_qr_codes
