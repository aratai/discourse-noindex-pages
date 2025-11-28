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
  # 2) FACEBOOK VIDEO OEMBED + DEBUG LOGY
  ##########################################

  # Toto JE dôležité: najprv načítať originálny engine z core
  require_dependency "onebox/engine/facebook_media_onebox"

  ::Onebox::Engine::FacebookMediaOnebox.class_eval do
    # helper na logovanie, nech to vieme ľahko filtrovať
    def fb_log(msg)
      Rails.logger.warn("[FB OEMBED] #{msg}")
    end

    def oembed_html
      token = SiteSetting.facebook_app_access_token

      if token.blank?
        fb_log("TOKEN EMPTY – skipping oEmbed for #{url}")
        return nil
      end

      fb_log("Trying Graph API for #{url}")
      query = URI.encode_www_form(url: url, access_token: token)
      oembed_url = "https://graph.facebook.com/v24.0/oembed_video?#{query}"

      fb_log("Request URL: #{oembed_url}")

      # fetch_response v Discourse vráti priamo BODY ako string
      body = ::Onebox::Helpers.fetch_response(oembed_url).to_s
      fb_log("RESPONSE BODY (first 300 chars): #{body[0..300]}")

      data = ::MultiJson.load(body)
      html = data["html"].to_s

      if html.empty?
        fb_log("EMPTY HTML returned from Graph API – parsed JSON keys: #{data.keys.join(", ")}")
        return nil
      end

      fb_log("HTML RECEIVED (length=#{html.length})")

      # fix na prípadné rozbité "https:/"
      html.gsub('src="https:/', 'src="https://')
    rescue => e
      fb_log("ERROR for #{url}: #{e.class} – #{e.message}")
      fb_log(e.backtrace.join("\n"))
      nil
    end

    def to_html
      fb_log("to_html CALLED for #{url}")

      if (html = oembed_html).present?
        fb_log("SUCCESS – using FB Graph oEmbed for #{url}")
        return html
      end

      fb_log("FALLBACK – oEmbed failed for #{url}, trying twitter player")

      metadata = get_twitter

      if metadata.present? && metadata[:card] == "player" && metadata[:player].present?
        fb_log("Using twitter player fallback for #{url}")

        return <<~HTML
          <iframe
            src="#{metadata[:player]}"
            width="#{metadata[:player_width]}"
            height="#{metadata[:player_height]}"
            scrolling="no"
            frameborder="0"
            allowfullscreen="true">
          </iframe>
        HTML
      end

      fb_log("FINAL FALLBACK – using generic OG onebox for #{url}")
      ::Onebox::Engine::AllowlistedGenericOnebox.new(url, @options || {}).to_html
    end
  end
end
