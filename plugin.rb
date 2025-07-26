# frozen_string_literal: true

# name: discourse-noindex-pages
# about: Adds noindex and canonical fix for topic subpages and specific post links
# version: 0.1
# authors: Tvoj Nick

after_initialize do

  # Patchne TopicsController, aby pridal canonical do HTTP hlavičky
  module ::TopicsControllerCanonicalAuto
    def show
      super

      url = request.fullpath
      # Nájde slug a topic_id z URL: /t/slug/123 alebo /t/slug/123?page=2 atď.
      if url =~ %r{^/t/([^/]+)/(\d+)}
        slug = $1
        topic_id = $2
        canonical_url = "https://infrastruktura.sk/t/#{slug}/#{topic_id}"

        # Pridaj do HTTP hlavičky
        response.headers["Link"] = "<#{canonical_url}>; rel=\"canonical\""
      end
    end
  end

  ::TopicsController.prepend ::TopicsControllerCanonicalAuto
  
  module CanonicalURL::Helpers
     def canonical_link_tag(url = nil)
        ""
     end
  end

end
