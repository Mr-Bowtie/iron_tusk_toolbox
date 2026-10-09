require "test_helper"

class ManapoolFetchOrdersServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "fetches all unfulfilled orders regardless of the last shipped order time" do
    original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    Order.create!(status: :shipped, placed_at: Time.zone.parse("2026-01-02 03:04:05 UTC"))

    client = ManapoolClient.singleton_class
    original_fetch_orders = ManapoolClient.method(:fetch_orders)
    calls = []

    client.send(:define_method, :fetch_orders) do |fulfilled:, since:|
      calls << { fulfilled: fulfilled, since: since }

      if fulfilled == true
        [ { "id" => "shipped-order" } ]
      else
        [ { "id" => "old-unfulfilled-order" }, { "id" => "new-unfulfilled-order" } ]
      end
    end

    assert_enqueued_jobs 3, only: Manapool::OrderHydrationJob do
      orders = Manapool::FetchOrdersService.call(fulfilled: "all")

      assert_equal [ "shipped-order", "old-unfulfilled-order", "new-unfulfilled-order" ], orders.map { |order| order["id"] }
    end

    assert_equal(
      [
        { fulfilled: true, since: "2026-01-02T03:04:05Z" },
        { fulfilled: false, since: Time.at(0).utc.iso8601 }
      ],
      calls
    )
  ensure
    clear_enqueued_jobs if ActiveJob::Base.queue_adapter.is_a?(ActiveJob::QueueAdapters::TestAdapter)
    ActiveJob::Base.queue_adapter = original_queue_adapter
    client.send(:define_method, :fetch_orders, original_fetch_orders)
  end
end
