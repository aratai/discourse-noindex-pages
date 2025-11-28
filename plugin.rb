# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.3
# authors: Tvoj Nick

extend_content_security_policy(
  script_src: ["https://connect.facebook.net"]
)

after_initialize do
  ##########################################
  # 1) NOINDEX PRE PAGINÁCIU TOPICOV
  ##########################################
  module ::TopicsControllerSEO
    def show
      url = request.fullpath
      is_pagination = url.include?("?page=") || url =~ %r{^/t/[^/]+/\d+/\d+}

      if is_pagination && request.user_agent&.include?("Googlebot")
        # zruš ETag/If-Modified-Since, nech má Googlebot vždy 200
        request.env.delete("HTTP_IF_MODIFIED_SINCE")
        request.env.delete("HTTP_IF_NONE_MATCH")
      end

      super

      if is_pagination
        response.headers["X-Robots-Tag"] = "noindex, follow"
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      end
    end
  end

  if defined?(::TopicsController)
    ::TopicsController.prepend ::TopicsControllerSEO
  else
    DiscourseEvent.on(:controllers_loaded) { ::TopicsController.prepend ::TopicsControllerSEO }
  end

  ##########################################
  # 2) FACEBOOK VIDEO OEMBED + DEBUG LOGY
  ##########################################

    require "cgi"
  require_dependency "onebox/engine/facebook_media_onebox"

  ::Onebox::Engine::FacebookMediaOnebox.class_eval do
    def to_html
      href = url

      # Rozhodneme, či ide o video, reel, share, alebo bežný post
      base =
        if href =~ /\/videos\//i || href.include?("/reel/") || href.include?("/share/v/")
          "https://www.facebook.com/plugins/video.php"
        else
          "https://www.facebook.com/plugins/post.php"
        end

      width  = 500
      height = 281

      src = "#{base}?href=#{CGI.escape(href)}&show_text=true&width=#{width}"

      <<~HTML
        <iframe
          src="#{src}"
          width="#{width}"
          height="#{height}"
          style="border:none;overflow:hidden"
          scrolling="no"
          frameborder="0"
          allowfullscreen="true"
          allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share">
        </iframe>
      HTML
    end
  end
end
