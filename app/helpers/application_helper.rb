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

  def image_upload_field(form, field_name, options = {})
    # Default options
    default_options = {
      max_file_size: 10 * 1024 * 1024, # 10MB for images
      allowed_types: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
      upload_path: 'images',
      button_text: 'Upload Image',
      button_class: 'px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700',
      required: false,
      class: ''
    }
    
    options = default_options.merge(options)
    field_id = "#{form.object_name}_#{field_name}"
    unique_id = "#{field_id}_#{SecureRandom.hex(4)}"
    
    render partial: 'shared/image_upload_field', locals: {
      form: form,
      field_name: field_name,
      field_id: field_id,
      unique_id: unique_id,
      options: options
    }
  end
end
