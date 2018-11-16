module Lit
  class ApplicationController < ActionController::Base
    include Lit::RequestLitVersionCheck
    include Pundit

    unless respond_to?(:before_action)
      alias_method :before_action, :before_filter
      alias_method :after_action, :after_filter
    end
    before_action :authenticate
    before_action :stop_hits_counter
    before_action :check_lit_version_keys_and_refresh
    after_action :restore_hits_counter

    private

    def current_user
      @current_user ||= Admin::SessionManager.current_user(session)
    end
    helper_method :current_user

    def authenticate
      if current_user.blank? || !policy(:translation).index?
        redirect_to "/admin/login?return_to=#{URI.parse(request.path).path}"
        return false
      end
    end

    def stop_hits_counter
      Lit.init.cache.stop_hits_counter
    end

    def restore_hits_counter
      Lit.init.cache.restore_hits_counter
    end

    def redirect_to_back_or_default(fallback_location: lit.localization_keys_path)
      if respond_to?(:redirect_back)
        redirect_back fallback_location: fallback_location
      else
        if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
          redirect_to :back
        else
          redirect_to fallback_location
        end
      end
    end
  end
end
