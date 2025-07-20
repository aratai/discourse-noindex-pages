# frozen_string_literal: true

# name: discourse-plugin-name
# about: Adds noindex to topic subpages and specific post links
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse + Tvoj Nick
# url: TODO
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do

  add_to_class(:topic_view, :add_extra_head) do |controller|
    noindex_needed = false

    if controller.params[:page].to_i > 1
      noindex_needed = true
    end

    if controller.params[:post_number]
      noindex_needed = true
    end

    if noindex_needed
      '<meta name="robots" content="noindex, follow">'
    else
      ''
    end
  end

end
