# frozen_string_literal: true

# Scrapes data from OpenStates.org and loads into the database
class StateRepUpdater
  attr_reader :state, :open_states_reps

  def self.update!
    metadata = OpenStates.metadata.objects
    metadata.each do |meta|
      state_abbr = meta.abbreviation
      chambers   = meta.chambers
      state      = State.find_by(abbr: state_abbr.upcase)
      state      = set_chambers_and_return_state(state, chambers)
      state.save

      update_state_legislators(state, attempt: 1)
    end
  end

  def self.update_state_legislators(state, attempt:)
    open_states_reps = OpenStates.legislators { |r| r.state = state.abbr.downcase }.objects

    # Recursively call method again if objects are nil, and give up after five attempts.
    if open_states_reps
      new(open_states_reps, state).update!
      OpenStates::Legislator.destroy_all
    elsif attempt <= 5
      update_state_legislators(state, attempt: attempt + 1)
    end
  end

  def self.set_chambers_and_return_state(state, chambers)
    case state.abbr
    when 'DC' then state.upper_chamber_title = 'Councilmember'
    when 'NE' then state.upper_chamber_title = 'Senator'
    else
      state.upper_chamber_title = chambers['upper']['title']
      state.lower_chamber_title = chambers['lower']['title'] if chambers['lower']
    end
    state
  end

  def initialize(open_states_reps, state)
    @state = state
    @open_states_reps = open_states_reps
  end

  def update!
    open_states_reps.each do |os_rep|
      district = StateDistrict.find_by(
        state: state, open_states_name: os_rep.district, chamber: os_rep.chamber
      )
      next unless district || %w[At-Large Chairman].include?(os_rep.district)
      add_or_update_rep(os_rep, district)
    end

    destroy_offices_with_no_phone_or_address
    deactivate_inactive_reps
  end

  def deactivate_inactive_reps
    ids = open_states_reps.map(&:leg_id)
    StateRep.where(state: state, active: true).where.not(official_id: ids).update(active: false)
  end

  def destroy_offices_with_no_phone_or_address
    OfficeLocation.
      includes(:rep).
      where(address: nil, phone: nil, reps: { type: 'StateRep' }).
      destroy_all
  end

  def add_or_update_rep(os_rep, district)
    rep          = StateRep.find_or_initialize_by(official_id: os_rep.leg_id)
    rep.district = district
    rep.state    = state
    update_personal_info(rep, os_rep)
    update_political_info(rep, os_rep)
    rep.add_photo if rep.photo_url != rep.photo
    rep.save
    puts "Updated #{state.abbr} #{rep.role} #{rep.official_full}"

    add_or_update_office_locations(rep, os_rep)
  end

  def update_political_info(rep, os_rep)
    rep.chamber = %w[DC NE].include?(rep.state.abbr) ? 'upper' : os_rep.chamber
    rep.contact_form = os_rep.email
    rep.party        = os_rep.party
    rep.active       = os_rep.active
    rep.photo_url    = os_rep.photo_url
    rep.photo        = os_rep.photo_url
    rep.level        = os_rep.level
    rep.url          = os_rep.url
  end

  def update_personal_info(rep, os_rep)
    rep.official_full = os_rep.full_name
    rep.last          = os_rep.last_name
    rep.first         = os_rep.first_name
    rep.middle        = os_rep.middle_name
    rep.suffix        = os_rep.suffixes
  end

  def add_or_update_office_locations(rep, os_rep)
    os_rep.offices.each do |os_off|
      off = rep.office_locations.find_or_initialize_by(
        office_type: os_off.type, rep: rep
      )
      update_fax_phone_and_address(rep, off, os_off)
      unless off.address.blank? && off.phone.blank?
        off.save
        puts "Updated #{rep.official_full}'s #{off.city} office"
      end
    end
  end

  def update_fax_phone_and_address(rep, off, os_off)
    return set_michigan_senator_office_info(off, os_off) if a_michigan_senator?(rep)
    trim_maryland_legislator_office_address(os_off) if a_maryland_legislator?
    off.fax     = !os_off.fax.blank?     ? os_off.fax     : off.fax
    off.phone   = !os_off.phone.blank?   ? os_off.phone   : off.phone
    off.address = !os_off.address.blank? ? os_off.address : off.address
  end

  def a_michigan_senator?(rep)
    rep.chamber == 'upper' && state.abbr == 'MI'
  end

  def set_michigan_senator_office_info(off, os_off)
    off.fax      = os_off.fax
    off.phone    = os_off.phone
    address      = os_off.address.match?(/Binsfeld/) ? '201 Townsend Street' : '100 N. Capitol Ave '
    off.building = os_off.address
    off.address  = "#{address}\nLansing\nMI\n48933"
  end

  def a_maryland_legislator?
    state.abbr == 'MD'
  end

  def trim_maryland_legislator_office_address(os_off)
    trim = os_off.address.match(/Fax:(\w|\W)+\z/)
    os_off.address.sub!(trim.to_s, '') if trim
  end
end
