class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2

  has_many :attendances
  has_many :hosts, through: :attendances
  has_many :guests, through: :attendances
end

