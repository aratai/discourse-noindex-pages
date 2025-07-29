# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.2
# authors: Tvoj Nick

after_initialize do

module ::TopicsControllerSEO
  def show
    super

    url = request.fullpath
    if url =~ %r{^/t/([^/]+)/(\d+)}
      slug = $1
      topic_id = $2
      canonical_url = "https://infrastruktura.sk/t/#{slug}/#{topic_id}"
      response.headers["Link"] = "<#{canonical_url}>; rel=\"canonical\""
      Rails.logger.warn("CANONICAL SET: #{canonical_url}")
    end

    if @topic
      archive_root_id = 40
      topic_cid = @topic.category_id
      Rails.logger.warn("TOPIC #{@topic.id} has category_id: #{topic_cid}")

      archive_ids = Category.where(parent_category_id: archive_root_id).pluck(:id)
      archive_ids << archive_root_id
      Rails.logger.warn("ARCHIVE IDS: #{archive_ids}")

      if archive_ids.include?(topic_cid)
        response.headers["X-Robots-Tag"] = "noindex, follow"
        Rails.logger.warn("NOINDEX APPLIED: Topic #{@topic.id}")
      else
        Rails.logger.warn("NOINDEX NOT APPLIED: Topic #{@topic.id} category_id #{topic_cid} not in archive_ids")
      end
    else
      Rails.logger.warn("NO @topic present in TopicsController#show")
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
