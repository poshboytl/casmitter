module ApplicationHelper
  include PaginationHelper
  
  def random_hacker_name
    @unix_name ||= ['nobody', 'root', 'daemon', 'tux', 'beastie', 'h4x0r', '1337', 'oneko'].sample
  end

  def markdown(text)
    return '' if text.blank?
    
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    raw markdown.render(text)
  end
end
