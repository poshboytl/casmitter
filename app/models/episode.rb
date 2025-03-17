class Episode < ApplicationRecord
  enum :status,  draft: 0, published: 1, hidden: 2

  has_many :attendances
  has_many :attendees, through: :attendances
  has_many :hosts, -> { where(attendances: { role: 'host' }) }, through: :attendances, source: :attendee
  has_many :guests, -> { where(attendances: { role: 'guest' }) }, through: :attendances, source: :attendee

  def cover_image_url
    cover_url.presence || 'logo.png'
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
end

