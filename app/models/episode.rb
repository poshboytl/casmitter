class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2
end
