# frozen_string_literal: true
module VCardable
  TEL_TYPES  = %w(home work cell pager other fax).freeze
  ADDR_TYPES = %w(home other).freeze

  def make_v_card
    @phones = []
    Vpim::Vcard::Maker.make2 do |maker|
      add_rep_name(maker)
      add_rep_photo(maker)
      add_contact_url(maker)
      add_primary_phone(maker)
      add_primary_address(maker)
      add_secondary_office(maker)
      maker.org = rep.role
    end
  end

  private

  def add_secondary_office(maker)
    index = 0
    rep.office_locations.order('office_type DESC').each do |office|
      next if office == self
      add_secondary_address(maker, office, index)
      add_secondary_phone(maker, office, index)
      index += 1
    end
  end

  def add_secondary_phone(maker, office, index)
    phone  = office.phone
    return if phone.blank? || index + 1 > TEL_TYPES.length || @phones.include?(phone)
    @phones << phone
    maker.add_tel(phone) do |tel|
      tel.preferred  = false
      tel.location   = TEL_TYPES[index]
      tel.capability = 'voice'
    end
  end

  def add_secondary_address(maker, office, index)
    return if index + 1 > ADDR_TYPES.length
    maker.add_addr do |addr|
      addr.preferred  = false
      addr.location   = ADDR_TYPES[index]
      addr.street     = office.suite ? "#{office.address}, #{office.suite}" : office.address
      addr.locality   = office.city
      addr.region     = office.state
      addr.postalcode = office.zip
    end
  end

  def add_primary_address(maker)
    maker.add_addr do |addr|
      addr.preferred  = true
      addr.location   = 'work'
      addr.street     = suite ? "#{address}, #{suite}" : address
      addr.locality   = city
      addr.region     = state
      addr.postalcode = zip
    end
  end

  def add_contact_url(maker)
    if rep.contact_form
      maker.add_url(rep.contact_form)
    elsif rep.url
      maker.add_url(rep.url)
    end
  end

  def add_primary_phone(maker)
    return if phone.blank?
    @phones << phone
    maker.add_tel(phone) do |tel|
      tel.preferred  = true
      tel.location   = 'work'
      tel.capability = 'voice'
    end
  end

  def add_rep_name(maker)
    maker.add_name do |name|
      name.prefix   = ''
      name.fullname = rep.official_full if rep.official_full
      name.given    = rep.first if rep.first
      name.family   = rep.last if rep.last
      name.suffix   = rep.suffix if rep.suffix
    end
  end

  def add_rep_photo(maker)
    begin
      web_photo = open(rep.photo) { |f| f.read }
    rescue => e
      logger.error e
    end

    return unless web_photo
    maker.add_photo do |photo|
      photo.image = web_photo
      photo.type  = 'JPEG'
    end
  end
end
