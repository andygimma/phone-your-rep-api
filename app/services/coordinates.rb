# frozen_string_literal: true

class Coordinates
  include Enumerable

  attr_reader :latlon

  def initialize(latlon: nil, lat: 0.0, long: 0.0)
    @latlon = latlon ? Array(latlon) : [lat.to_f, long.to_f] - [0.0]
  end

  def each(&block)
    latlon.each(&block)
  end

  def last
    latlon.last
  end

  def [](index)
    latlon[index]
  end

  def lat
    latlon[0]
  end

  def lon
    latlon[1]
  end

  def empty?
    latlon.empty?
  end

  def blank?
    latlon.blank?
  end

  def find_district_geom
    if latlon.empty?
      NullObject.new
    else
      DistrictGeom.containing_latlon(lat, lon).includes(district: :state).take
    end
  end
end
