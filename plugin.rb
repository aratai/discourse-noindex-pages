# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  Rails.logger.info "[SEO Plugin] Starting initialization..."

  # Pridáme meta tagy do crawler layoutu
  add_to_class(:topic_view, :crawler_noindex_tag) do
    Rails.logger.info "[SEO Plugin] Generating noindex tag:"
    Rails.logger.info "  - URL: #{scope.request.fullpath}"
    Rails.logger.info "  - Params: #{scope.params.inspect}"
    
    url = scope.request.fullpath
    page = scope.params[:page].to_i
    has_post_number = url.match?(/\/\d+\/\d+$/) || scope.params[:post_number].present?

    Rails.logger.info "  - Page: #{page}"
    Rails.logger.info "  - Has post number: #{has_post_number}"

    result = if page > 1 || has_post_number
      Rails.logger.info "  => Adding noindex tag"
      '<meta name="robots" content="noindex, follow">'
    else
      Rails.logger.info "  => No noindex needed"
      ''
    end

    Rails.logger.info "  - Result: #{result}"
    result
  end

  add_to_class(:topic_view, :crawler_canonical_tag) do
    Rails.logger.info "[SEO Plugin] Generating canonical tag:"
    canonical_url = "#{Discourse.base_url}#{topic.relative_url}"
    Rails.logger.info "  - Canonical URL: #{canonical_url}"
    
    result = "<link rel='canonical' href='#{canonical_url}'>"
    Rails.logger.info "  - Result: #{result}"
    result
  end

  # Pridáme meta tagy do hlavičky
  register_html_builder('server:before-head-close-crawler') do |controller|
    Rails.logger.info "[SEO Plugin] Processing HTML builder:"
    Rails.logger.info "  - Controller: #{controller.class.name}"
    
    unless controller.is_a?(TopicsController)
      Rails.logger.info "  => Skipping: Not a TopicsController"
      next ''
    end

    topic_view = controller.instance_variable_get(:@topic_view)
    unless topic_view&.topic
      Rails.logger.info "  => Skipping: No topic view or topic"
      next ''
    end

    Rails.logger.info "  - Topic: #{topic_view.topic.title}"
    
    result = [
      topic_view.crawler_noindex_tag,
      topic_view.crawler_canonical_tag
    ].join("\n")

    Rails.logger.info "  - Final HTML: #{result}"
    result
  end

  Rails.logger.info "[SEO Plugin] Initialization complete"
end
