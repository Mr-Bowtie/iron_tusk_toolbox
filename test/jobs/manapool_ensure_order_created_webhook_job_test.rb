require "test_helper"

class ManapoolEnsureOrderCreatedWebhookJobTest < ActiveJob::TestCase
  test "delegates to the webhook ensure service" do
    service = Manapool::EnsureOrderCreatedWebhookService.singleton_class
    original_service_call = Manapool::EnsureOrderCreatedWebhookService.method(:call)

    called = false

    service.send(:define_method, :call) do
      called = true
    end

    Manapool::EnsureOrderCreatedWebhookJob.perform_now

    assert called
  ensure
    service.send(:define_method, :call, original_service_call)
  end
end
