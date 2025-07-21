# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  # Pridáme meta tagy do serializéra
  add_to_serializer(:topic_view, :seo_meta_tags) do
    return '' unless object.topic

    url = scope.request.fullpath
    page = scope.request.params[:page].to_i
    has_post_number = url.match?(/\/\d+\/\d+$/) || scope.request.params[:post_number].present?

    meta = ""

    if page > 1 || has_post_number
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

  # Pridáme meta tagy do hlavičky
  register_html_builder('server:before-head-close') do |controller|
    if controller.instance_of?(TopicsController)
      topic_view = controller.instance_variable_get(:@topic_view)
      next '' unless topic_view&.topic

      url = controller.request.fullpath
      page = controller.params[:page].to_i
      has_post_number = url.match?(/\/\d+\/\d+$/) || controller.params[:post_number].present?

      result = ''

      if page > 1 || has_post_number
        Rails.logger.info "[SEO Plugin] Adding noindex meta tag"
        result += '<meta name="robots" content="noindex, follow">'
      end

      canonical = "#{Discourse.base_url}#{topic_view.topic.relative_url}"
      result += %Q(<link rel="canonical" href="#{canonical}" />)

      result
    else
      ''
    end
  end

  # Zabezpečíme, že sa meta tagy dostanú do hlavičky
  on(:topic_view_serializer_after_init) do |serializer|
    serializer.include_seo_meta_tags = true
  end
end
