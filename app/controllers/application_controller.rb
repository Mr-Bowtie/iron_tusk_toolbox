class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_sentry_context
  around_action :with_request_context

  private

  def with_request_context
    Monitoring::RequestContext.request_id = request.request_id
    Monitoring::RequestContext.controller = controller_path
    Monitoring::RequestContext.action = action_name
    Monitoring::RequestContext.method = request.request_method
    Monitoring::RequestContext.path = request.fullpath
    Monitoring::RequestContext.format = request.format&.symbol.to_s
    Monitoring::RequestContext.user_id = current_user&.id
    yield
  ensure
    Monitoring::RequestContext.reset
  end

  def configure_sentry_context
    return unless defined?(Sentry)

    Sentry.set_tags(
      request_id: request.request_id,
      controller: controller_path,
      action: action_name
    )

    if current_user
      Sentry.set_user(id: current_user.id, email: current_user.email)
    else
      Sentry.set_user({})
    end
  end
end
