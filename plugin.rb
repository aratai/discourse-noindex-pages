# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  Rails.logger.info "[SEO Plugin] Initializing SEO improvements plugin"

  add_to_serializer(:topic_view, :extra_noindex) do
    Rails.logger.debug "[SEO Plugin] Starting extra_noindex check for URL: #{scope&.request&.fullpath}"
    
    unless should_process?
      Rails.logger.debug "[SEO Plugin] Skipping noindex - should_process? returned false"
      return ''
    end

    url = scope.request.fullpath
    params = object.instance_variable_get(:@params)
    
    Rails.logger.debug "[SEO Plugin] Processing URL: #{url}"
    Rails.logger.debug "[SEO Plugin] Params: #{params.inspect}"
    
    has_post_number = url.match?(/\/\d+\/\d+$/)
    is_paged = params && params[:page].to_i > 1
    
    Rails.logger.debug "[SEO Plugin] Has post number: #{has_post_number}"
    Rails.logger.debug "[SEO Plugin] Is paged: #{is_paged}"
    
    result = if is_paged || has_post_number
      Rails.logger.info "[SEO Plugin] Adding noindex meta tag for URL: #{url}"
      '<meta name="robots" content="noindex, follow">'
    else
      Rails.logger.debug "[SEO Plugin] No noindex needed for URL: #{url}"
      ''
    end

    Rails.logger.debug "[SEO Plugin] Final noindex result: #{result}"
    result
  end

  add_to_serializer(:topic_view, :canonical_url) do
    Rails.logger.debug "[SEO Plugin] Starting canonical_url generation"
    
    unless should_process?
      Rails.logger.debug "[SEO Plugin] Skipping canonical - should_process? returned false"
      return ''
    end
    
    base_url = Discourse.base_url_no_prefix
    topic_url = object.topic.relative_url
    
    Rails.logger.debug "[SEO Plugin] Base URL: #{base_url}"
    Rails.logger.debug "[SEO Plugin] Topic URL: #{topic_url}"
    
    # Odstránime parametre page a post_number z URL pre canonical
    clean_url = topic_url.split('?').first
    clean_url = clean_url.split('/').reject { |part| part.match?(/^\d+$/) }.join('/')
    
    final_url = "#{base_url}#{clean_url}"
    Rails.logger.debug "[SEO Plugin] Generated canonical URL: #{final_url}"
    
    final_url
  end

  add_to_serializer(:topic_view, :should_process?) do
    result = scope.is_a?(Guardian) && 
             scope.request.format == :html && 
             object.respond_to?(:topic) && 
             object.topic

    Rails.logger.debug "[SEO Plugin] should_process? checks:"
    Rails.logger.debug "  - Is Guardian? #{scope.is_a?(Guardian)}"
    Rails.logger.debug "  - Is HTML? #{scope.request.format == :html}"
    Rails.logger.debug "  - Has topic? #{object.respond_to?(:topic)}"
    Rails.logger.debug "  - Topic exists? #{object.topic.present?}"
    Rails.logger.debug "  - Final result: #{result}"

    result
  end

  Rails.logger.info "[SEO Plugin] SEO improvements plugin initialized successfully"
end
