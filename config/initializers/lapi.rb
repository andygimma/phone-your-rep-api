# frozen_string_literal: true

module OpenStates
  LAPI.new 'OpenStates' do |api|
    api.base_uri = 'https://www.openstates.org/api/v1/'
    api.key      = :apikey, ENV['OPENSTATES_API_KEY']

    api.add_resource :legislators do
      optional_params :state, :first_name, :last_name, :chamber,
                      :active, :term, :district, :party, :lat, :long

      add_attributes :first_name, :last_name, :middle_name, :district, :chamber,
                     :url, :created_at, :updated_at, :email, :active, :state,
                     :full_name, :leg_id, :party, :suffixes, :id, :photo_url,
                     :level, :fax

      add_collections :offices

      add_scopes democrat: -> { where party: 'Democratic' },
                 republican: -> { where party: 'Republican' }
    end

    api.add_resource :offices do
      add_attributes :fax, :name, :phone, :address, :type, :email
    end

    api.add_resource :districts do
      add_attributes :abbr, :boundary_id, :chamber, :id, :name, :num_seats, :shape

      add_collections :legislators
    end

    api.add_resource :metadata do
      add_attributes :name, :abbreviation, :chambers
    end
  end
end
