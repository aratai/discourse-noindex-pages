# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.2
# authors: Tvoj Nick

after_initialize do

  module ::TopicsControllerSEO
    def show
      super

      # Nastav canonical hlavičku
      url = request.fullpath
      if url =~ %r{^/t/([^/]+)/(\d+)}
        slug = $1
        topic_id = $2
        canonical_url = "https://infrastruktura.sk/t/#{slug}/#{topic_id}"
        response.headers["Link"] = "<#{canonical_url}>; rel=\"canonical\""
        Rails.logger.warn("CANONICAL SET: #{canonical_url}")
      end

      # Nastav noindex pre archiv
      if @topic
        archive_root_id = 40

        # Získaj všetky ID podkategórií archívu
        archive_ids = Category.where(parent_category_id: archive_root_id).pluck(:id)
        archive_ids << archive_root_id

        if archive_ids.include?(@topic.category_id)
          response.headers["X-Robots-Tag"] = "noindex, follow"
          Rails.logger.warn("NOINDEX APPLIED: Topic #{@topic.id} in archive by ID")
        else
          Rails.logger.warn("NOINDEX SKIPPED: Topic #{@topic.id} not in archive")
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
