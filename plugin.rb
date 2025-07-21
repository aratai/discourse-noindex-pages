# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  # Prepend to TopicsController to add X-Robots-Tag
  module ::TopicsControllerNoindexAuto
    def show
      super

      url = request.fullpath
      page = params[:page].to_i
      has_post_number = url.match?(/\/\d+\/\d+$/) || params[:post_number].present?

      if page > 1 || has_post_number
        response.headers["X-Robots-Tag"] = "noindex, follow"
      end
    end
  end

  ::TopicsController.prepend ::TopicsControllerNoindexAuto

  # Inject <meta name="robots"> into HTML head
  register_html_builder('server:before-head-close') do |controller|
    url = controller.request.fullpath
    page = controller.params[:page].to_i
    has_post_number = url.match?(/\/\d+\/\d+$/) || controller.params[:post_number].present?

    if page > 1 || has_post_number
      '<meta name="robots" content="noindex, follow">'
    else
      ''
    end
  end

end
