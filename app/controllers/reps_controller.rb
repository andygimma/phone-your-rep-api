# frozen_string_literal: true

class RepsController < ApplicationController
  before_action :set_rep, only: :show
  after_action :make_impression, only: :index
  has_scope :independent,
            :republican,
            :democrat,
            type: :boolean,
            only: [:index]

  # GET /reps
  def index
    address, lat, long = geo_params

    if address || lat || long
      geo   = GeoLookup.new address: address, lat: lat, long: long
      @reps = geo.find_reps
      return if @reps.blank?
      @district = @reps.detect(&:district).try(:district)
    elsif params[:generate] == 'true'
      @reps = apply_scopes(Rep).active.order(:bioguide_id)
    else
      send_index_files :reps
    end
  end

  # GET /reps/1
  def show; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_rep
    @rep = Rep.find_by(bioguide_id: params[:id])
  end

  def make_impression
    return if @district.blank?
    impressionist @district, '', unique: [:ip_address]
  end
end
