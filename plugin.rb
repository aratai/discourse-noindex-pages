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
  def has_html?
    true
  end

  def to_html
    original_href = url
    
    # 1. Čistenie URL
    cleaned_href = original_href.split("?").first
    
    # 2. Detekcia typu obsahu
    is_reel = cleaned_href.include?("/reel/")
    is_video = cleaned_href =~ /\/videos\//i || cleaned_href.include?("/share/v/") || is_reel

    # 3. Nastavenie triedy a URL pre embed
    if is_video || is_reel
      # Ak je to VIDEO/REEL
      class_name = "fb-video"
      href_to_embed = cleaned_href # Použijeme čistú URL
      fallback_label = "Otvoriť video na Facebooku"
    else
      # Ak je to ŠTANDARDNÝ POST (vrátane permalink.php)
      class_name = "fb-post"
      # Pre posty je potrebné nechať špecifické query parametre, inak sa neidentifikujú
      href_to_embed = original_href

      fallback_label = "Otvoriť príspevok na Facebooku"
    end

    # 4. Generovanie DOM elementu
    <<~HTML
      <div class="#{class_name}" 
           data-href="#{href_to_embed}" 
           data-show-text="true"
           data-allowfullscreen="true">
        <blockquote cite="#{href_to_embed}" class="fb-xfbml-parse-ignore">
          <a href="#{href_to_embed}">#{fallback_label}</a>
        </blockquote>
      </div>

      <div class="fb-embed-fallback">
        <a href="#{href_to_embed}" rel="nofollow ugc noopener" target="_blank">#{fallback_label}</a>
      </div>
    HTML
  end
end
end
