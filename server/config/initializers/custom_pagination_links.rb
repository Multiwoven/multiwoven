# This module monkey patches the pagination links defined by the json-api adapter_options
# to more closely match the specifications
module CustomPaginationLinks
  FIRST_PAGE = 1

  def as_json
    per_page = collection.try(:per_page) || collection.try(:limit_value) || collection.size
    pagination_links = pages_from.each_with_object({}) do |(key, value), hash|
      # Use the non nested syntax for pagination params
      params = query_parameters.merge(page: value, per_page: per_page).to_query
      # Changed this to set the value to nil when no value is specified by pages_from
      hash[key] = value.present? ? "#{url(adapter_options)}?#{params}" : nil
    end
    # Always include self, regardless of pagination links existing or not.
    { self: "#{url(adapter_options)}?#{query_parameters.to_query}" }.merge(pagination_links)
  end

  private

  # Changed these to allow nil values, this way the keys are always present, but possibly null
  def pages_from
    #return {} if collection.total_pages <= FIRST_PAGE
    {}.tap do |pages|
      pages[:first] = FIRST_PAGE
      pages[:prev] = first_page? ? nil : collection.current_page - FIRST_PAGE
      pages[:next] = (!last_page? && collection.total_pages > 1) ? collection.current_page + FIRST_PAGE : nil
      pages[:last] = [collection.total_pages, FIRST_PAGE].max
    end
  end

  def first_page?
    collection.current_page == FIRST_PAGE
  end

  def last_page?
    collection.current_page == collection.total_pages
  end
end

ActiveModelSerializers::Adapter::JsonApi::PaginationLinks.prepend CustomPaginationLinks
ActiveModelSerializers.config.adapter = :json_api
