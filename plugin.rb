# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.3
# authors: Tvoj Nick

after_initialize do
  ##
  # 1) NOINDEX PRE PAGINÁCIU TOPICOV
  ##
  module ::TopicsControllerSEO
    def show
      url = request.fullpath
      is_pagination = url.include?("?page=") || url =~ %r{^/t/[^/]+/\d+/\d+}

      if is_pagination && request.user_agent&.include?("Googlebot")
        # Bezpečne odstrániť cache hlavičky – nech to vždy vráti 200 pre Googlebota
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
    DiscourseEvent.on(:controllers_loaded) do
      ::TopicsController.prepend ::TopicsControllerSEO
    end
  end

  ##
  # 2) FACEBOOK VIDEO OEMBED CEZ GRAPH API
  ##
  require "uri"
  require "multi_json"

  module ::Onebox
    module Engine
      # reopen existujúci engine, nemeníme matches_regexp ani includes
      class FacebookMediaOnebox
        # placeholder (aby stránka neskákala pri načítaní videa)
        def placeholder_html
          ::Onebox::Helpers.video_placeholder_html
        end

        def oembed_html
          token = SiteSetting.facebook_app_access_token
          return nil if token.blank?

          query = URI.encode_www_form(
            url: url,
            access_token: token
          )

          oembed_url = "https://graph.facebook.com/v24.0/oembed_video?#{query}"

          response = ::Onebox::Helpers.fetch_response(oembed_url)
          data = ::MultiJson.load(response.body)

          html = data["html"].to_s
          return nil if html.empty?

          # fix na prípadné rozbité "https:/"
          html.gsub('src="https:/', 'src="https://')
        rescue => e
          # Ak oEmbed zlyhá, len ticho spadneme na fallback
          # (žiadne logovanie, nech to nespamuje logy)
          nil
        end

        def to_html
          # 1) skúsime Meta oEmbed
          if (html = oembed_html).present?
            return html
          end

          # 2) fallback – pôvodné správanie (Twitter card player ak existuje)
          metadata = get_twitter
          if metadata.present? && metadata[:card] == "player" && metadata[:player].present?
            <<~HTML
              <iframe
                src="#{metadata[:player]}"
                width="#{metadata[:player_width]}"
                height="#{metadata[:player_height]}"
                scrolling="no"
                frameborder="0"
                allowfullscreen="true">
              </iframe>
            HTML
          else
            # 3) úplný fallback – generický onebox (to čo si mal doteraz)
            ::Onebox::Engine::AllowlistedGenericOnebox.new(url, @options || {}).to_html
          end
        end
      end
    end
  end
end
