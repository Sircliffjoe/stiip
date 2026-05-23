module ApplicationHelper
  def safe_external_url(url)
    return nil if url.blank?
    
    parsed = URI.parse(url)
    if %w(http https).include?(parsed.scheme)
      url
    else
      # If no scheme but looks like a domain, prefix with http
      if !url.start_with?("javascript:", "data:", "file:")
        "http://#{url}"
      else
        nil
      end
    end
  rescue URI::InvalidURIError
    nil
  end
end
