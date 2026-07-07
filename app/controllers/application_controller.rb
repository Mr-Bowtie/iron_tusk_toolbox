class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_sentry_context

  private

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
