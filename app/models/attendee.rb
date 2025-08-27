class Attendee < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :episodes, through: :attendances
  
  # social_links is a JSONB column storing social media links as key-value pairs
  # Example: { "X": "https://x.com/username", "Mastodon": "https://mastodon.social/@username" }
  store :social_links, coder: JSON
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :type, inclusion: { in: %w[Host Guest], message: "must be either Host or Guest" }
  validates :bio, length: { maximum: 200 }
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }, allow_blank: true
  validate :social_links_must_be_valid_structure

  scope :hosts, -> { where(type: 'Host') }
  scope :guests, -> { where(type: 'Guest') }

  def display_type
    type || 'Attendee'
  end

  def avatar_image_url
    avatar_url.presence || 'https://via.placeholder.com/150/cccccc/666666?text=Avatar'
  end

  def episode_count
    episodes.count
  end

  def published_episode_count
    episodes.published.count
  end

  def social_links_present?
    social_links.present? && social_links.any? { |_, url| url.present? }
  end

  private

  def social_links_must_be_valid_structure
    return if social_links.blank?

    # Ensure social_links is a Hash (flat structure)
    unless social_links.is_a?(Hash)
      errors.add(:social_links, "must be a valid JSON object")
      return
    end

    social_links.each do |platform, url|
      # Ensure key is a string
      unless platform.is_a?(String)
        errors.add(:social_links, "platform names must be strings")
        next
      end

      # Ensure value is a string (URL)
      unless url.is_a?(String)
        errors.add(:social_links, "URL for #{platform} must be a string")
        next
      end

      # Ensure URL is valid format
      unless url.present? && url.start_with?('http')
        errors.add(:social_links, "must be a valid URL for #{platform}")
      end
    end
  end
end
