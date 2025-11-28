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

  is_video =
    href =~ /\/videos\//i ||
    href.include?("/reel/") ||
    href.include?("/share/v/")

  base = is_video ?
    "https://www.facebook.com/plugins/video.php" :
    "https://www.facebook.com/plugins/post.php"

  # Len odporúčaný width – aj tak ho prepíšeme CSSkom
  width = 600

  src = "#{base}?href=#{CGI.escape(href)}&show_text=true&width=#{width}"

  <<~HTML
    <div class="fb-embed-wrapper">
      <iframe
        src="#{src}"
        width="100%"
        height="auto"
        scrolling="no"
        frameborder="0"
        allowfullscreen="true"
        allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
        style="border:none;overflow:hidden;aspect-ratio:4/5;">
      </iframe>
    </div>
  HTML
end
  end
end
