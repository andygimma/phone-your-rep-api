# frozen_string_literal: true

class OfficeLocation < ApplicationRecord
  include AddressParser
  include HasOfficialID
  include HasLevel

  # Set a "PYR_S3_BUCKET" environment variable to your own S3 Bucket
  # if you want to use your own generated QR Codes.
  S3_BUCKET = Rails.configuration.s3_bucket

  belongs_to :rep, foreign_key: :official_id, primary_key: :official_id
  has_many   :issues

  validates :rep, presence: true

  before_validation :geocode, if: :needs_geocoding?

  geocoded_by :geocoder_address

  after_validation :set_city_state_and_zip, if: -> { rep.type == 'StateRep' }

  before_save :reverse_geocode, if: -> { state.blank? }

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    geo = results.first
    if geo
      obj.state = geo.state_code
      obj.zip   = geo.postal_code
    end
  end

  before_save :set_official_id,
              :set_bioguide_or_state_leg_id,
              :set_office_id,
              :set_level,
              :set_qr_code_link

  scope :active, -> { where(active: true) }

  scope :sorted_by_distance, ->(coordinates) { near(coordinates, 10_000) }

  scope :capitol, -> { where office_type: 'capitol' }

  scope :district, -> { where office_type: 'district' }

  scope :rep_type, ->(type) { joins(:rep).where(reps: { type: type }) }

  scope :state, lambda { |name|
    where(
      id: Rep.state(name).joins(:office_locations).pluck('office_locations.id')
    )
  }

  is_impressionable counter_cache: true, column_name: :downloads

  dragonfly_accessor :qr_code

  attr_reader :distance

  def set_office_id
    return unless office_id.blank?
    self.office_id = if office_type == 'capitol'
                       "#{official_id}-capitol"
                     elsif rep.is_a?(StateRep)
                       "#{official_id}-#{office_type}"
                     else
                       "#{official_id}-#{city}"
                     end
  end

  def set_bioguide_or_state_leg_id
    if rep.is_a?(CongressionalRep) && bioguide_id.blank?
      self.bioguide_id = official_id
    elsif rep.is_a?(StateRep) && state_leg_id.blank?
      self.state_leg_id = official_id
    end
  end

  def needs_geocoding?
    latitude.blank? || longitude.blank?
  end

  def add_qr_code_img
    self.qr_code = RQRCode::QRCode.new(
      make_v_card(photo: false).to_s,
      size: 28,
      level: :h
    ).as_png(size: 360).to_string
    qr_code.name = "#{office_id}.png"
    save
  end

  def make_v_card(photo: true)
    VCardBuilder.new(self, rep).make_v_card(photo: photo)
  end

  def full_address
    "#{address}, #{city_state_zip}"
  end

  def city_state_zip
    [city, state, zip].join(' ')
  end

  def geocoder_address
    rep.is_a?(Governor) ? city_state_zip : full_address
  end

  def calculate_distance(coordinates)
    return if needs_geocoding?
    @distance = Geocoder::Calculations.distance_between(coordinates, [latitude, longitude]).round(1)
  end

  def v_card_link
    if Rails.env.production?
      "https://phone-your-rep.herokuapp.com/v_cards/#{office_id}"
    else
      "http://localhost:3000/v_cards/#{office_id}"
    end
  end

  def set_qr_code_link
    return unless office_id
    sub_directory = case rep.type
                    when 'CongressionalRep' then 'congress'
                    when 'Governor'         then 'governors'
                    when 'StateRep'         then rep.state.abbr.downcase
                    end
    self.qr_code_link =
      "https://s3.amazonaws.com/#{S3_BUCKET}/#{sub_directory}/#{office_id.tr('-', '_')}.png"
  end
end
