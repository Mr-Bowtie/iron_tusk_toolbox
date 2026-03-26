module MatrixAlerts
  class NewOrderService < ApplicationService
    def self.call(order_details)
      msg = %Q(
        New Order!
        #{order_details["shipping_address"]["name"]}: $#{order_details["total_cents"].to_f / 100}
      )

      MatrixClient.send_message(msg)
    end
  end
end
