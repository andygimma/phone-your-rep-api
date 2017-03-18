# frozen_string_literal: true

namespace :pyr do
  namespace :qr_codes do
    desc 'Generate QR code images for all office locations'
    task :generate do
      OfficeLocation.where(active: true).each { |o| o.add_qr_code_img }
    end

    desc 'Remove the image meta files'
    task :clean do
      source_file = get_source_file
      Dir.chdir(source_file.to_s) do
        sh 'rm *meta.yml'
      end
    end

    desc 'Empty the S3 bucket'
    task :empty do
      sh 'aws s3 rm s3://phone-your-rep-images --recursive'
    end

    desc 'Upload images to S3 bucket'
    task :upload do
      source_file = get_source_file
      Dir.chdir(source_file.to_s) do
        sh 'aws s3 cp . s3://phone-your-rep-images/ --recursive --grants'\
          ' read=uri=http://acs.amazonaws.com/groups/global/AllUsers'
      end
    end

    desc 'Delete images source file'
    task :delete do
      source_file = get_source_file
      sh "rm -rf #{source_file.to_s}"
    end

    desc 'Generate QR codes, upload to S3 bucket, and delete locally'
    task create: [:generate, :clean, :empty, :upload, :delete]

    desc 'Export QR Code UIDs from CSV file'
    task :export do
      offices = OfficeLocation.where(active: true)
      header = %w(id qr_code_uid qr_code_name)
      file = Rails.root.join('lib', 'qr_codes.csv').to_s
      CSV.open(file, 'wb') do |csv|
        csv << header
        i = 0
        offices.each do |o|
          csv << [o.office_id, o.qr_code_uid, o.qr_code_name]
          i += 1
        end
        puts "Exported #{i} QR codes"
      end
    end

    desc 'Import QR Code UIDs from CSV file'
    task :import do
      i = 0
      CSV.foreach(Rails.root.join('lib', 'qr_codes.csv')) do |row|
        next if row[0] == 'id'
        o = OfficeLocation.find_by(office_id: row[0])
        # o.update(qr_code_uid: row[4], qr_code_name: row[5])
        if o
          o.update(qr_code_uid: row[1], qr_code_name: row[2])
          i += 1
          if ENV['verbose'] == 'true'
            puts o.rep.official_full
            puts row[1], row[2]
            puts i
          end
        end
      end
      puts "Imported #{i} QR codes"
    end

    def get_source_file
      if ENV['source_file']
        ENV['source_file']
      else
        month = Date.today.month.to_s
        day = Date.today.day.to_s
        m = month.length == 1 ? "0#{month}" : month
        d = day.length == 1 ? "0#{day}" : day
        y = Date.today.year.to_s
        Rails.root.join(
          'public/system/dragonfly/development', y, m, d
        )
      end
    end
  end
end
