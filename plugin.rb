# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.3
# authors: Tvoj Nick

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
  # 2) FACEBOOK IFRAME ONEBOX (BEZ OEMBED)
  ##########################################

  require "cgi"
  require "uri"
  require_dependency "onebox/engine/facebook_media_onebox"

  ::Onebox::Engine::FacebookMediaOnebox.class_eval do
    # Povieme oneboxu, že vraciame hotové HTML (nie URL na oEmbed)
    def has_html?
      true
    end

    def to_html
      href = url

      # Rozhodneme, či je to video / reel / share, alebo obyčajný post
      is_video =
        href =~ /\/videos\//i ||
        href.include?("/reel/") ||
        href.include?("/share/v/")

      base =
        if is_video
          "https://www.facebook.com/plugins/video.php"
        else
          "https://www.facebook.com/plugins/post.php"
        end

      # Rovnaké čísla, ako ručne vložený iframe
      width  = 500
      height = is_video ? 281 : 576

      params = {
        "href"      => href,
        "show_text" => "true",
        "width"     => width
      }

      src = "#{base}?#{URI.encode_www_form(params)}"

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
