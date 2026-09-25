# frozen_string_literal: true

module Monitoring
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :request_id, :controller, :action, :method, :path, :format, :user_id
  end
end
