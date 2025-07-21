# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  add_to_serializer(:topic_view, :extra_noindex) do
    if should_noindex?
      '<meta name="robots" content="noindex, follow">'
    else
      ''
    end
  end

  add_to_serializer(:topic_view, :should_noindex?) do
    return false unless should_process?

    url = scope.request.fullpath
    params = object.instance_variable_get(:@params)
    
    has_post_number = url.match?(/\/\d+\/\d+$/)
    is_paged = params && params[:page].to_i > 1
    
    is_paged || has_post_number
  end

  add_to_serializer(:topic_view, :should_process?) do
    scope.is_a?(Guardian) && 
    scope.request.format == :html && 
    object.respond_to?(:topic) && 
    object.topic
  end

  add_to_serializer(:topic_view, :canonical_url) do
    return '' unless should_process?
    
    base_url = Discourse.base_url_no_prefix
    topic_url = object.topic.relative_url
    
    "#{base_url}#{topic_url}"
  end
end
