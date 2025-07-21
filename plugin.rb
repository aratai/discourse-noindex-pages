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
      Rails.logger.info "----------------------------------------"
      Rails.logger.info "[SEO Plugin] Processing request:"
      Rails.logger.info "  - Format: #{request.format}"
      Rails.logger.info "  - URL: #{request.fullpath}"
      Rails.logger.info "  - Params: #{params.inspect}"
      
      return unless request.format.html?
      return unless @topic_view&.topic

      url = request.fullpath
      page = params[:page].to_i
      post_number = params[:post_number]
      has_post_number = url.match?(/\/\d+\/\d+$/) || post_number.present?

      Rails.logger.info "[SEO Plugin] Analysis:"
      Rails.logger.info "  - Page number: #{page}"
      Rails.logger.info "  - Post number: #{post_number}"
      Rails.logger.info "  - Has post number: #{has_post_number}"

      # Pridáme meta tagy priamo do response body
      if page > 1 || has_post_number
        meta_tag = '<meta name="robots" content="noindex, follow">'
        response.body = response.body.sub('</head>', "#{meta_tag}</head>") if response.body

        # Pridáme aj header
        response.headers['X-Robots-Tag'] = 'noindex, follow'
        
        Rails.logger.info "[SEO Plugin] Added noindex tags:"
        Rails.logger.info "  - Meta tag: #{meta_tag}"
        Rails.logger.info "  - Header: X-Robots-Tag: noindex, follow"
      end

      # Pridáme canonical URL
      canonical_url = "#{Discourse.base_url}#{@topic_view.topic.relative_url}"
      canonical_tag = %Q(<link rel="canonical" href="#{canonical_url}">)
      response.body = response.body.sub('</head>', "#{canonical_tag}</head>") if response.body

      Rails.logger.info "[SEO Plugin] Added canonical URL: #{canonical_url}"
      Rails.logger.info "----------------------------------------"
    end
  end
end
