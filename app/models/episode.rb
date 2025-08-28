class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2, preview: 3

  validates :name, presence: true
  validates :number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }
  validates :preview_token, uniqueness: true, allow_nil: true

  has_many :attendances
  has_many :attendees, through: :attendances
  has_many :hosts, -> { where(attendances: { role: 'host' }) }, through: :attendances, source: :attendee
  has_many :guests, -> { where(attendances: { role: 'guest' }) }, through: :attendances, source: :attendee

  before_save :auto_assign_published_fields, if: :status_changed_to_published?
  before_create :generate_preview_token

  scope :published, -> { where(status: :published) }

  def cover_image_url
    cover_url.presence || ActionController::Base.helpers.asset_path('logo.png')
  end

  def summary_with_desc
    markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    
    html_desc = markdown_renderer.render(desc)
    "<p>#{summary}</p><br><br>#{html_desc}"
  end

  def duration_in_hours
    return "00:00:00" if duration.nil? || duration.zero?
    
    hours = duration / 3600
    minutes = (duration % 3600) / 60
    seconds = duration % 60
    
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def attendee_names
    attendees.map(&:name).join(', ')
  end

  def self.next_available_number
    maximum_number = published.maximum(:number) || 0
    maximum_number + 1
  end

  def guest_ids=(ids)
    if ids.blank?
      self.guests = []
    else
      guests = Attendee.where(id: ids)
      self.guests = guests
    end
  end
  
  def host_ids=(ids)
    if ids.blank?
      self.hosts = []
    else
      hosts = Attendee.where(id: ids)
      self.hosts = hosts
    end
  end

  private

  def status_changed_to_published?
    status_changed? && published? && !status_was.to_s.inquiry.published?
  end

  def generate_preview_token
    loop do
      self.preview_token = SecureRandom.uuid
      break unless Episode.exists?(preview_token: preview_token)
    end
  end

  def auto_assign_published_fields
    # Auto-assign episode number if blank
    if number.blank?
      max_retry = 5
      retry_count = 0
      
      begin
        self.number = self.class.next_available_number
        retry_count += 1
      rescue ActiveRecord::RecordNotUnique
        retry if retry_count < max_retry
        raise
      end
    end
    
    # Auto-assign published_at if blank (only if it's truly nil or empty string)
    if published_at.nil? || published_at == ""
      self.published_at = Time.current
    end
  end
end

