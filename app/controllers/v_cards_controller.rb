# frozen_string_literal: true
class VCardsController < ApplicationController
  def show
    @office = OfficeLocation.find_with_rep(params.require(:id)).first
    @rep    = @office.rep

    send_data @office.v_card, filename: "#{@rep.official_full} #{@rep.state.abbr}.vcf"
    impressionist @office, '', unique: [:impressionable_type, :impressionable_id, :ip_address]
  end
end
