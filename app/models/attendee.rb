class Attendee < ApplicationRecord
  has_many :attendances
  has_many :episodes, through: :attendances
end
