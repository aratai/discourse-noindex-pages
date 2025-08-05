# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.2
# authors: Tvoj Nick

after_initialize do
module ::TopicsControllerSEO
  def show
    # --- Kontrola pagináciách PRED super ---
    url = request.fullpath
    is_pagination = url.include?('?page=') || url =~ %r{^/t/[^/]+/\d+/\d+}
    
    # Pre paginácie: vynútiť 200 namiesto 304 pre Googlebot
    if is_pagination && request.user_agent&.include?('Googlebot')
      request.headers.delete('If-Modified-Since')
      request.headers.delete('If-None-Match')
      Rails.logger.warn("FORCED 200 FOR GOOGLEBOT PAGINATION: #{url}")
    end
    
    super
    
    # --- Noindex pre paginácie ---
    if is_pagination
      response.headers["X-Robots-Tag"] = "noindex, follow"
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      Rails.logger.warn("NOINDEX PAGINATION: #{url}")
    else
      Rails.logger.warn("MAIN TOPIC PAGE: #{url}")
    end
  end
end
  ::TopicsController.prepend ::TopicsControllerSEO
end
