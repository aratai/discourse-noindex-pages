# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex to archive topics and canonical headers for pagination
# version: 0.2
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

    # --- Noindex ---
    topic = @topic || Topic.find_by(id: params[:topic_id])
    if topic
      archive_root_id = 40
      topic_cid = topic.category_id
      Rails.logger.warn("TOPIC #{topic.id} has category_id: #{topic_cid}")

      archive_ids = Category.where(parent_category_id: archive_root_id).pluck(:id)
      archive_ids << archive_root_id
      Rails.logger.warn("ARCHIVE IDS: #{archive_ids}")

      if archive_ids.include?(topic_cid)
        response.headers["X-Robots-Tag"] = "noindex, follow"
        Rails.logger.warn("NOINDEX APPLIED: Topic #{topic.id}")
      else
        Rails.logger.warn("NOINDEX NOT APPLIED: Topic #{topic.id} category_id #{topic_cid} not in archive_ids")
      end
    else
      Rails.logger.warn("NO TOPIC FOUND with id=#{params[:topic_id]}")
    end
  end
end


  ::TopicsController.prepend ::TopicsControllerSEO

module ::SitemapExtension
  def sitemap_topics
    archive_root_id = 40
    archive_ids = Category.where(parent_category_id: archive_root_id).pluck(:id) + [archive_root_id]

    Rails.logger.warn("[SITEMAP] sitemap_topics called for #{name}")
    Rails.logger.warn("[SITEMAP] Archive category_ids: #{archive_ids}")

    indexable_topics = Topic.where(visible: true)
      .joins(:category)
      .where(categories: { read_restricted: false })

    if name == Sitemap::RECENT_SITEMAP_NAME
      indexable_topics = indexable_topics.where("bumped_at > ?", 3.days.ago).order(bumped_at: :desc)
    elsif name == Sitemap::NEWS_SITEMAP_NAME
      indexable_topics = indexable_topics.where("bumped_at > ?", 72.hours.ago).order(bumped_at: :desc)
    else
      offset = (name.to_i - 1) * max_page_size
      indexable_topics = indexable_topics.order(id: :asc).limit(max_page_size).offset(offset)
    end

    Rails.logger.warn("[SITEMAP] Final topic count: #{indexable_topics.count}")

    now = Time.now.utc

    # Namiesto Topic objektov vráť polia v rovnakom formáte ako očakáva view
    indexable_topics.map do |t|
      [
        t.id,
        t.slug,
        archive_ids.include?(t.category_id) ? now : t.bumped_at,
        t.updated_at,
        t.posts_count
      ]
    end
  end
end

::Sitemap.prepend(::SitemapExtension)


  module ::CanonicalURL::Helpers
    def canonical_link_tag(url = nil)
      ""
    end
  end
end
