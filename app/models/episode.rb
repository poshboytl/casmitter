class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2

  has_many :attendances
  has_many :attendees, through: :attendances
  has_many :hosts, -> { where(type: 'Host') }, through: :attendances, source: :attendee
  has_many :guests, -> { where(type: 'Guest') }, through: :attendances, source: :attendee
end

