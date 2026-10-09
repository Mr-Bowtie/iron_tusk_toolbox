require "rails_helper"

RSpec.describe MatrixAlerts::NewOrderService do
  describe ".call" do
    it "formats the order details and sends the message via MatrixClient" do
      order_details = {
        "shipping_address" => { "name" => "Jane Doe" },
        "total_cents" => 1234,
        order_count: 5
      }

      Order.create!(status: :unfulfilled)
      Order.create!(status: :unfulfilled)
      Order.create!(status: :shipped)

      expect(MatrixClient).to receive(:send_message).with(include("Jane Doe", "$12.34", "Total unfulfilled orders: 5"))

      described_class.call(order_details)
    end
  end
end
