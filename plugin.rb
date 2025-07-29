# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Sets noindex for archive topics and canonical headers for pagination
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  module ::TopicsControllerSEO
    def show
      super

      # --- Canonical ---
      url = request.fullpath
      if url =~ %r{^/t/([^/]+)/(\d+)}
        slug = $1
        topic_id = $2
        canonical_url = "https://infrastruktura.sk/t/#{slug}/#{topic_id}"
        response.headers["Link"] = "<#{canonical_url}>; rel=\"canonical\""
        Rails.logger.warn("CANONICAL SET: #{canonical_url}")
      end

      # --- Noindex for archive ---
      if @topic
        archive_root = Category.find_by(slug: "archiv-monitoringu-tlace")

        if archive_root && @topic.category
          archive_ids = [archive_root.id] + archive_root.subcategories.pluck(:id)

          if archive_ids.include?(@topic.category_id)
            response.headers["X-Robots-Tag"] = "noindex, follow"
            Rails.logger.warn("NOINDEX APPLIED: Topic #{@topic.id} in archive")
          else
            Rails.logger.warn("NOINDEX SKIPPED: Topic #{@topic.id} not in archive")
          end
        end
      end
    end
  end

  ::TopicsController.prepend ::TopicsControllerSEO

  module ::CanonicalURL::Helpers
    def canonical_link_tag(url = nil)
      ""
    end
  end

end
