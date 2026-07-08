require "test_helper"

class ManapoolEnsureOrderCreatedWebhookServiceTest < ActiveSupport::TestCase
  ClientDouble = Struct.new(:webhooks_response, :registered_args, keyword_init: true) do
    def fetch_webhooks
      webhooks_response
    end

    def register_webhook(topic:, callback_url:)
      self.registered_args = {
        topic: topic,
        callback_url: callback_url
      }
    end
  end

  test "registers the canonical order_created webhook when missing" do
    client = ClientDouble.new(webhooks_response: { "webhooks" => [] })

    created = Manapool::EnsureOrderCreatedWebhookService.call(client: client)

    assert_equal true, created
    assert_equal(
      {
        topic: "order_created",
        callback_url: "https://toolbox.batb.love/orders/new_order"
      },
      client.registered_args
    )
  end

  test "does not register when the canonical order_created webhook already exists" do
    client = ClientDouble.new(
      webhooks_response: {
        "webhooks" => [
          {
            "topic" => "order_created",
            "callback_url" => "https://toolbox.batb.love/orders/new_order"
          }
        ]
      }
    )

    created = Manapool::EnsureOrderCreatedWebhookService.call(client: client)

    assert_equal false, created
    assert_nil client.registered_args
  end
end
