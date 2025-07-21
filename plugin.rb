# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  Rails.logger.info "[SEO Plugin] Starting initialization..."

  TopicsController.class_eval do
    before_action :set_seo_meta_tags, only: :show

    private

    def set_seo_meta_tags
      Rails.logger.info "[SEO Plugin] Request format: #{request.format}"
      Rails.logger.info "[SEO Plugin] URL: #{request.fullpath}"
      
      # Spracujeme len HTML requesty
      return unless request.format.html?
      return unless @topic_view&.topic

      url = request.fullpath
      page = params[:page].to_i
      has_post_number = url.match?(/\/\d+\/\d+$/) || params[:post_number].present?

      Rails.logger.info "[SEO Plugin] Processing HTML request:"
      Rails.logger.info "  - Page: #{page}"
      Rails.logger.info "  - Has post number: #{has_post_number}"
      Rails.logger.info "  - Params: #{params.inspect}"

      if page > 1 || has_post_number
        @meta_tags ||= []
        @meta_tags << { name: 'robots', content: 'noindex, follow' }
        response.headers['X-Robots-Tag'] = 'noindex, follow'
        Rails.logger.info "[SEO Plugin] Added noindex meta tag"
      end

      @canonical_url = "#{Discourse.base_url}#{@topic_view.topic.relative_url}"
      Rails.logger.info "[SEO Plugin] Set canonical URL: #{@canonical_url}"
    end
  end

  # Override the default head template
  module MetaTagsInHead
    def discourse_stylesheet_tags
      Rails.logger.info "[SEO Plugin] Rendering head tags"
      Rails.logger.info "  - Meta tags: #{@meta_tags.inspect}"
      Rails.logger.info "  - Canonical: #{@canonical_url}"
      
      result = super
      if @meta_tags
        @meta_tags.each do |tag|
          result << "<meta name='#{tag[:name]}' content='#{tag[:content]}'>\n"
        end
      end
      if @canonical_url
        result << "<link rel='canonical' href='#{@canonical_url}'>\n"
      end
      result.html_safe
    end
  end

  ApplicationHelper.module_eval do
    prepend MetaTagsInHead
  end

  Rails.logger.info "[SEO Plugin] Initialization complete"
end
