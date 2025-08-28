module PaginationHelper
  def render_pagination(collection, options = {})
    return unless collection.respond_to?(:current_page) && collection.total_pages > 1
    
    render partial: 'shared/pagination', locals: { 
      collection: collection,
      options: options
    }
  end
  
  def pagination_info(collection)
    return unless collection.respond_to?(:current_page)
    
    from = collection.offset_value + 1
    to = [collection.offset_value + collection.limit_value, collection.total_count].min
    
    "Showing #{from} to #{to} of #{collection.total_count} results"
  end
end
