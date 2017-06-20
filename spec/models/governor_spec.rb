# frozen_string_literal: true

require 'rails_helper'

describe Governor, type: :model do
  before :all do
    @state        = create :state, abbr: 'VT'
    @office_one   = create :office_location, active: false
    @office_two   = create :office_location, latitude: 4.0, longitude: 4.0
    @office_three = create :office_location, latitude: 2.0, longitude: 2.0
    @office_four  = create :office_location, latitude: 3.0, longitude: 3.0
    @avatar       = create :avatar

    @rep = create(
      :governor,
      official_full: 'Phil Scott',
      first: 'Phil',
      last: 'Scott',
      state: @state,
      office_locations: [@office_one, @office_two, @office_three, @office_four],
      avatar: @avatar
    )
  end

  after(:all) { [Rep, State, OfficeLocation, Avatar].each(&:destroy_all) }

  it 'has an official full name' do
    expect(@rep.official_full).to eq('Phil Scott')
  end

  it 'constructs an official_id based on the name and state' do
    expect(@rep.official_id).to eq('VT-phil-scott')
  end

  it 'belongs_to a state' do
    expect(@rep.state).to eq(@state)
  end

  it 'has many office_locations' do
    expect(@rep.office_locations).to be_a(ActiveRecord::Relation)
    expect(@rep.office_locations.count).to eq(4)
    expect(@rep.office_locations).to include(@office_one)
    expect(@rep.office_locations).to include(@office_two)
    expect(@rep.office_locations).to include(@office_three)
    expect(@rep.office_locations).to include(@office_four)
  end

  it 'has many active_office_locations' do
    expect(@rep.active_office_locations).to be_a(ActiveRecord::Relation)
    expect(@rep.active_office_locations.count).to eq(3)
    expect(@rep.active_office_locations).not_to include(@office_one)
    expect(@rep.active_office_locations).to include(@office_two)
    expect(@rep.active_office_locations).to include(@office_three)
    expect(@rep.active_office_locations).to include(@office_four)
  end

  it 'has an avatar' do
    expect(@rep.avatar).to be(@avatar)
  end

  it 'has constructs a photo_url based on its bioguide_id' do
    photo_url = 'https://www.nga.org/files/live/sites/NGA/files/images/govportraits/VT-PhilScott.jpg'

    expect(@rep.photo_url).to eq(photo_url)
  end

  it '#fetch_avatar_data updates its avatar with data for its own photo_url' do
    expect(@avatar.data).to be(nil)

    @rep.fetch_avatar_data
    data = open(@rep.photo_url, &:read)

    expect(@avatar.data).not_to be(nil)
    expect(@avatar.data).to eq(data)
  end

  it '#fetch_avatar_data creates an avatar if one does not already exist' do
    rep = create :governor
    expect(rep.avatar).to be(nil)
    rep.add_photo
    expect(rep.avatar).to be_a(Avatar)
  end

  it '#add_photo updates the photo attribute if the #photo_url returns valid data' do
    expect(@rep.photo).to be(nil)

    @rep.add_photo

    expect(@rep.photo).to eq(@rep.photo_url)
  end

  it '#add_photo ensures the photo attribute is nil if #photo_url does not return valid data' do
    rep = create :governor, bioguide_id: 'not-found'
    rep.add_photo

    expect(rep.photo).to be(nil)
  end

  context '#sorted_offices_array' do
    context 'when #sort_offices is not called' do
      it 'will return its active_office_locations unsorted' do
        expect(@rep.sorted_offices).to be(nil)
        expect(@rep.sorted_offices_array).not_to eq(@rep.sorted_offices)
        expect(@rep.sorted_offices_array).not_to include(@office_one)
        expect(@rep.sorted_offices_array).to include(@office_two)
        expect(@rep.sorted_offices_array).to include(@office_three)
        expect(@rep.sorted_offices_array).to include(@office_four)
      end
    end

    context 'when #sort_offices is called' do
      it 'will return its active_office_locations sorted by distance' do
        @rep.sort_offices [0.0, 0.0]

        expect(@rep.sorted_offices_array).to eq(@rep.sorted_offices)
        expect(@rep.sorted_offices).not_to include(@office_one)
        expect(@rep.sorted_offices.first).to eq(@office_three)
        expect(@rep.sorted_offices.second).to eq(@office_four)
        expect(@rep.sorted_offices.third).to eq(@office_two)
      end

      it 'will calculate distance for each active_office_location' do
        @rep.sort_offices [0.0, 0.0]
        sorted_offices = @rep.sorted_offices

        expect(sorted_offices.third.distance).to be > sorted_offices.second.distance
        expect(sorted_offices.second.distance).to be > sorted_offices.first.distance
        expect(sorted_offices.first.distance).to be > 0.0
      end
    end
  end
end