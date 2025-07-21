# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  add_to_serializer(:topic_view, :seo_meta_tags) do
    return '' unless object.topic

    url = scope.request.fullpath
    is_paged = object.instance_variable_get(:@params)[:page].to_i > 1
    has_post_number = url.match?(/\/\d+\/\d+$/) || scope.params[:post_number].present?

    meta = ""

    if is_paged || has_post_number
      Rails.logger.info "[SEO Plugin] Adding noindex to: #{url}"
      meta += '<meta name="robots" content="noindex, follow">'
    else
      Rails.logger.info "[SEO Plugin] Noindex not needed for: #{url}"
    end

    canonical = "#{Discourse.base_url}#{object.topic.relative_url}"
    Rails.logger.info "[SEO Plugin] Setting canonical: #{canonical}"
    meta += %Q(<link rel="canonical" href="#{canonical}" />)

    meta
  end

end
