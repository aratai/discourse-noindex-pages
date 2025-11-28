# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.3
# authors: Tvoj Nick

after_initialize do
  ##########################################
  # 1) NOINDEX FOR PAGINATED TOPICS
  ##########################################
  module ::TopicsControllerSEO
    def show
      url = request.fullpath
      is_pagination = url.include?("?page=") || url =~ %r{^/t/[^/]+/\d+/\d+}

      if is_pagination && request.user_agent&.include?("Googlebot")
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
  # 2) FACEBOOK VIDEO OEMBED DEBUG LOGGING
  ##########################################

  require "uri"
  require "multi_json"

  module ::Onebox
    module Engine
      class FacebookMediaOnebox

        # pridáme log z konštruktora, aby sme vedeli, že engine sa načítal
        def initialize(url, options)
          Rails.logger.warn("[FB OEMBED] FacebookMediaOnebox INITIALIZED for #{url}")
          super
        end

        def placeholder_html
          ::Onebox::Helpers.video_placeholder_html
        end

        def oembed_html
          token = SiteSetting.facebook_app_access_token

          if token.blank?
            Rails.logger.warn("[FB OEMBED] TOKEN EMPTY – skipping oEmbed for #{url}")
            return nil
          end

          Rails.logger.warn("[FB OEMBED] Trying Graph API for #{url}")
          query = URI.encode_www_form(url: url, access_token: token)
          oembed_url = "https://graph.facebook.com/v24.0/oembed_video?#{query}"

          Rails.logger.warn("[FB OEMBED] Request URL: #{oembed_url}")

          response = ::Onebox::Helpers.fetch_response(oembed_url)
          Rails.logger.warn("[FB OEMBED] HTTP #{response.code} for #{url}")

          body = response.body.to_s
          Rails.logger.warn("[FB OEMBED] RESPONSE BODY (first 300 chars): #{body[0..300]}")

          data = ::MultiJson.load(body)
          html = data["html"].to_s

          if html.empty?
            Rails.logger.warn("[FB OEMBED] EMPTY HTML returned from Graph API")
            return nil
          end

          Rails.logger.warn("[FB OEMBED] HTML RECEIVED (length=#{html.length})")

          html.gsub('src="https:/', 'src="https://')
        rescue => e
          Rails.logger.warn("[FB OEMBED] ERROR for #{url}: #{e.class} – #{e.message}")
          Rails.logger.warn(e.backtrace.join("\n"))
          nil
        end

        def to_html
          Rails.logger.warn("[FB OEMBED] to_html CALLED for #{url}")

          if (html = oembed_html).present?
            Rails.logger.warn("[FB OEMBED] SUCCESS – using FB Graph oEmbed for #{url}")
            return html
          end

          Rails.logger.warn("[FB OEMBED] FALLBACK – oEmbed failed for #{url}, trying twitter player")

          metadata = get_twitter

          if metadata.present? && metadata[:card] == "player"
            Rails.logger.warn("[FB OEMBED] Using twitter player fallback for #{url}")

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

          Rails.logger.warn("[FB OEMBED] FINAL FALLBACK – using generic OG onebox for #{url}")
          ::Onebox::Engine::AllowlistedGenericOnebox.new(url, @options || {}).to_html
        end

      end
    end
  end
end
