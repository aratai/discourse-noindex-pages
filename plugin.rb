# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  Rails.logger.info "[SEO Plugin] Starting initialization..."

  # Pridáme helper metódy do ApplicationHelper
  ApplicationHelper.class_eval do
    def seo_meta_tags
      return "" unless @topic_view&.topic

      Rails.logger.info "[SEO Plugin] Generating SEO meta tags for: #{request.fullpath}"
      
      url = request.fullpath
      page = params[:page].to_i
      has_post_number = url.match?(/\/\d+\/\d+$/) || params[:post_number].present?

      Rails.logger.info "  - Page: #{page}"
      Rails.logger.info "  - Has post number: #{has_post_number}"
      
      result = []

      # Noindex tag
      if page > 1 || has_post_number
        Rails.logger.info "  => Adding noindex tag"
        result << '<meta name="robots" content="noindex, follow">'
      end

      # Canonical URL
      canonical_url = "#{Discourse.base_url}#{@topic_view.topic.relative_url}"
      Rails.logger.info "  => Setting canonical: #{canonical_url}"
      result << %Q(<link rel="canonical" href="#{canonical_url}">)

      final_result = result.join("\n")
      Rails.logger.info "  - Final tags: #{final_result}"
      final_result.html_safe
    end
  end

  # Pridáme helper do zoznamu SEO tagov
  on(:topic_view_seo_tags) do |tags, topic_view|
    Rails.logger.info "[SEO Plugin] Adding SEO tags to topic view"
    tags << :seo_meta_tags
  end

  Rails.logger.info "[SEO Plugin] Initialization complete"
end
