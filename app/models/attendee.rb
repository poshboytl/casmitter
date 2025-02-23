class Attendee < ApplicationRecord
  has_many :attendances
  has_many :episodes, through: :attendances
  
  store :social_links, accessors: [:weibo, :twitter], coder: JSON
end
