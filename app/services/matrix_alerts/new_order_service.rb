module MatrixAlerts
  class NewOrderService < ApplicationService
    def self.call(order_details)
      unfulfilled_orders_count = Order.unfulfilled.count

      msg = %Q(
        New Order!
        #{order_details["shipping_address"]["name"]}: $#{order_details["total_cents"].to_f / 100}
        Total unfulfilled orders: #{unfulfilled_orders_count}
      )

      MatrixClient.send_message(msg)
    end
  end
end
