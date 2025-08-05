# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.2
# authors: Tvoj Nick

after_initialize do
  module ::TopicsControllerSEO
    def show
      url = request.fullpath
      is_pagination = url.include?('?page=') || url =~ %r{^/t/[^/]+/\d+/\d+}

      if is_pagination && request.user_agent&.include?('Googlebot')
        # Bezpečne odstrániť cache hlavičky
        request.env.delete('HTTP_IF_MODIFIED_SINCE')
        request.env.delete('HTTP_IF_NONE_MATCH')
        Rails.logger.warn("FORCED 200 FOR GOOGLEBOT PAGINATION: #{url}")
      end

      super

      if is_pagination
        response.headers["X-Robots-Tag"] = "noindex, follow"
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        Rails.logger.warn("NOINDEX PAGINATION: #{url}")
      else
        Rails.logger.warn("MAIN TOPIC PAGE: #{url}")
      end
    end
  end

  if defined?(::TopicsController)
    ::TopicsController.prepend ::TopicsControllerSEO
  else
    DiscourseEvent.on(:controllers_loaded) do
      ::TopicsController.prepend ::TopicsControllerSEO
    end
  end
end
