module Manapool
  class EnsureOrderCreatedWebhookService < ApplicationService
    TOPIC = "order_created"
    CALLBACK_URL = "https://toolbox.batb.love/orders/new_order"

    def self.call(client: ManapoolClient)
      webhooks = client.fetch_webhooks.fetch("webhooks", [])

      if registered?(webhooks)
        Monitoring::Reporter.log(
          :info,
          "ManaPool order_created webhook already registered",
          topic: TOPIC,
          callback_url: CALLBACK_URL
        )
        return false
      end

      client.register_webhook(topic: TOPIC, callback_url: CALLBACK_URL)
      Monitoring::Reporter.log(
        :info,
        "ManaPool order_created webhook registered",
        topic: TOPIC,
        callback_url: CALLBACK_URL
      )
      true
    end

    def self.registered?(webhooks)
      webhooks.any? do |webhook|
        topic = webhook["topic"] || webhook[:topic]
        callback_url = webhook["callback_url"] || webhook[:callback_url]

        topic == TOPIC && callback_url == CALLBACK_URL
      end
    end
    private_class_method :registered?
  end
end
