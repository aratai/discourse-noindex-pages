# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  # Helper method to check if we're dealing with HTML request and have a valid topic
  def should_process?(scope, object)
    scope.is_a?(Guardian) && 
    scope.request.format == :html && 
    object.respond_to?(:topic) && 
    object.topic
  end

  # Helper to determine if current page should be noindexed
  def should_noindex?(scope, object)
    return false unless should_process?(scope, object)

    url = scope.request.fullpath
    params = object.instance_variable_get(:@params)
    
    has_post_number = url.match?(/\/\d+\/\d+$/)
    is_paged = params && params[:page].to_i > 1
    
    is_paged || has_post_number
  end

  add_to_serializer(:topic_view, :extra_noindex) do
    if should_noindex?(scope, object)
      '<meta name="robots" content="noindex, follow">'
    else
      ''
    end
  end

  add_to_serializer(:topic_view, :canonical_url) do
    return '' unless should_process?(scope, object)
    
    base_url = Discourse.base_url_no_prefix
    topic_url = object.topic.relative_url
    
    # Always point canonical to the first page/main topic URL
    "#{base_url}#{topic_url}"
  end
end

