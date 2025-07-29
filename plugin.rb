# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex for archive category and canonical headers for paginated/topic-post URLs
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  # NOINDEX pre archiv-monitoringu-tlace a jeho podkategórie
  module ::TopicsControllerNoindexAuto
    def show
      super

      if @topic
        archive_parent_slug = "archiv-monitoringu-tlace"
        topic_category = @topic.category

        if topic_category &&
           (topic_category.slug == archive_parent_slug ||
            topic_category.ancestors.any? { |c| c.slug == archive_parent_slug })

          response.headers["X-Robots-Tag"] = "noindex, follow"
        end
      end
    end
  end

  # CANONICAL pre všetky stránkované alebo konkrétne posty
  module ::TopicsControllerCanonicalAuto
    def show
      super

      url = request.fullpath
      if url =~ %r{^/t/([^/]+)/(\d+)}
        slug = $1
        topic_id = $2
        canonical_url = "https://infrastruktura.sk/t/#{slug}/#{topic_id}"
        response.headers["Link"] = "<#{canonical_url}>; rel=\"canonical\""
      end
    end
  end

  ::TopicsController.prepend ::TopicsControllerNoindexAuto
  ::TopicsController.prepend ::TopicsControllerCanonicalAuto

  # Odstráni <link rel="canonical"> z HTML hlavičky (necháme len HTTP header)
  module ::CanonicalURL::Helpers
    def canonical_link_tag(url = nil)
      ""
    end
  end

end
