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

##########################################
# 3) INSTAGRAM OEMBED (TOKENLESS, OFICIÁLNA DOKUMENTÁCIA)
##########################################
require "net/http"
require "json"
require "digest"
require_dependency "onebox/engine/instagram_onebox"

::Onebox::Engine::InstagramOnebox.class_eval do
  def has_html?
    true
  end

  def to_html
    cleaned_href = clean_url
    cache_key = "ig_oembed_#{Digest::SHA1.hexdigest(cleaned_href)}"
    cached = Rails.cache.read(cache_key)
    return cached if cached

    begin
      uri = URI("https://graph.facebook.com/v25.0/instagram_oembed?url=#{CGI.escape(cleaned_href)}&omitscript=true")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        html = data["html"]
        if html.present?
          Rails.cache.write(cache_key, html, expires_in: 7.days)
          html
        else
          fallback_html(cleaned_href)
        end
      else
        fallback_html(cleaned_href)
      end
    rescue => e
      Rails.logger.warn("IG oEmbed failed for #{cleaned_href}: #{e.message}")
      fallback_html(cleaned_href)
    end
  end

  private

  def fallback_html(href)
    <<~HTML
      <div class="ig-embed-fallback">
        <a href="#{href}" rel="nofollow ugc noopener" target="_blank">Otvoriť príspevok na Instagrame</a>
      </div>
    HTML
  end
end
end
