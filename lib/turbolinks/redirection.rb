module Turbolinks
  module Redirection
    extend ActiveSupport::Concern

    included do
      before_action :set_turbolinks_location_header_from_session if respond_to?(:before_action)
    end

    def redirect_to(url = {}, options = {})
      turbolinks = options.delete(:turbolinks)

      super.tap do
        # Consider turbolinks multipart requests as turbolink-visitable as well.
        # This is due to limitations of remote multipart forms in Rails:
        # they are sent as HTML instead of JS.
        # With this patch we are asuming any multipart form is also remote
        # (we make sure of that in the app).
        # if turbolinks != false && request.xhr? && !request.get?
        if turbolinks != false && (request.xhr? || ((request.post? || request.put? || request.patch?) && request.content_type == 'multipart/form-data')) && !request.get?          visit_location_with_turbolinks(location, turbolinks)
          visit_location_with_turbolinks(location, turbolinks)
        else
          if request.headers["Turbolinks-Referrer"]
            store_turbolinks_location_in_session(location)
          end
        end
      end
    end

    private
      def visit_location_with_turbolinks(location, action)
        visit_options = {
          action: ["advance", "replace", "back"].include?(action.to_s) ? action : "replace"
        }

        script = []
        script << "Turbolinks.clearCache()"
        script << "Turbolinks.visit(#{location.to_json}, #{visit_options.to_json})"

        self.status = 200
        self.response_body = script.join("\n")
        response.content_type = "text/javascript"
      end

      def store_turbolinks_location_in_session(location)
        session[:_turbolinks_location] = location if session
      end

      def set_turbolinks_location_header_from_session
        if session && session[:_turbolinks_location]
          response.headers["Turbolinks-Location"] = session.delete(:_turbolinks_location)
        end
      end
  end
end
