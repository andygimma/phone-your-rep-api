# frozen_string_literal: true
class State < ApplicationRecord
  has_many :districts, foreign_key: :state_code, primary_key: :state_code
  has_many :reps
  scope    :by_abbr_with_districts, ->(abbr:) { where(abbr: abbr).includes(:districts).first }

  FACTORY = RGeo::Geographic.simple_mercator_factory
end
