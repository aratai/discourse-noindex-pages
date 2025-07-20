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

add_to_serializer(:topic_view, :extra_noindex) do
  url = scope.request.fullpath
  has_post_number = url.match(/\/\d+\/\d+$/)
  is_paged = object.instance_variable_get(:@params)[:page].to_i > 1

  if is_paged || has_post_number
    '<meta name="robots" content="noindex, follow">'
  else
    ''
  end
end

end
