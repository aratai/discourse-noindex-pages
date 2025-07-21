# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  Rails.logger.info "[SEO Plugin] Initializing SEO improvements plugin"

  # Pridáme custom meta tagy do hlavičky
  register_html_builder('server:before-head-close') do |controller|
    if controller.instance_of?(TopicsController)
      Rails.logger.debug "[SEO Plugin] Processing TopicsController request"
      
      topic_view = controller.instance_variable_get(:@topic_view)
      return '' unless topic_view&.topic

      url = controller.request.fullpath
      page = controller.params[:page].to_i
      
      Rails.logger.debug "[SEO Plugin] URL: #{url}, Page: #{page}"
      
      has_post_number = url.match?(/\/\d+\/\d+$/)
      is_paged = page > 1

      result = ''
      
      if is_paged || has_post_number
        Rails.logger.info "[SEO Plugin] Adding noindex for URL: #{url}"
        result += '<meta name="robots" content="noindex, follow">'
      end

      # Nastavíme canonical URL
      base_url = Discourse.base_url
      topic_url = topic_view.topic.relative_url
      clean_url = topic_url.split('?').first.split('/').reject { |part| part.match?(/^\d+$/) }.join('/')
      canonical = "#{base_url}#{clean_url}"
      
      Rails.logger.debug "[SEO Plugin] Setting canonical URL: #{canonical}"
      result += %Q(<link rel="canonical" href="#{canonical}" />)

      result
    else
      ''
    end
  end

  Rails.logger.info "[SEO Plugin] SEO improvements plugin initialized successfully"
end
