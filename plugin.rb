# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  add_to_serializer(:topic_view, :extra_noindex) do
    if scope.is_a?(Guardian) && scope.request.format == :html && object.respond_to?(:topic) && object.topic
      url = scope.request.fullpath
      has_post_number = url.match(/\/\d+\/\d+$/)
      is_paged = object.instance_variable_get(:@params)[:page].to_i > 1

      if is_paged || has_post_number
        '<meta name="robots" content="noindex, follow">'
      else
        ''
      end
    else
      ''
    end
  end

  add_to_serializer(:topic_view, :canonical_url) do
    if scope.is_a?(Guardian) && scope.request.format == :html && object.respond_to?(:topic) && object.topic
      params = object.instance_variable_get(:@params)
      has_post_number = scope.request.fullpath.match(/\/\d+\/\d+$/)
      is_paged = params[:page].to_i > 1

      if is_paged || has_post_number
        Discourse.base_url_no_prefix + object.topic.relative_url
      else
        Discourse.base_url_no_prefix + object.topic.relative_url
      end
    else
      Discourse.base_url_no_prefix + object.topic.relative_url
    end
  end

end

