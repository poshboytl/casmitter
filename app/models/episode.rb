class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2

  has_many :attendances
  has_many :attendees, through: :attendances
  has_many :hosts, -> { where(attendances: { role: 'host' }) }, through: :attendances, source: :attendee
  has_many :guests, -> { where(attendances: { role: 'guest' }) }, through: :attendances, source: :attendee
end

