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
    href = url
    
    # Očistíme URL od zbytočných sledovacích parametrov 
    if href.include?("?")
      href = href.split("?").first
    end

    # Vygenerujeme DOM element, ktorý Facebook SDK očakáva
    <<~HTML
      <div class="fb-video" 
           data-href="#{href}" 
           data-width="500" 
           data-show-text="true">
        <blockquote cite="#{href}" class="fb-xfbml-parse-ignore">
          <a href="#{href}">Facebook Video</a>
        </blockquote>
      </div>
    HTML
  end
end
end
