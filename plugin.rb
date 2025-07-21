# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do
  TopicsController.class_eval do
    before_action :set_seo_meta_tags, only: :show

    private

    def set_seo_meta_tags
      return unless @topic_view&.topic

      url = request.fullpath
      page = params[:page].to_i
      has_post_number = url.match?(/\/\d+\/\d+$/) || params[:post_number].present?

      if page > 1 || has_post_number
        @meta_tags ||= []
        @meta_tags << { name: 'robots', content: 'noindex, follow' }
        response.headers['X-Robots-Tag'] = 'noindex, follow'
      end

      # Set canonical URL
      @canonical_url = "#{Discourse.base_url}#{@topic_view.topic.relative_url}"
    end
  end

  # Override the default head template
  module MetaTagsInHead
    def discourse_stylesheet_tags
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
end
