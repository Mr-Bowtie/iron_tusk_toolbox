require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @order = orders(:one)
    @user = FactoryBot.create(:user)
    sign_in @user
  end

  test "should get index" do
    get orders_url
    assert_response :success
  end

  test "should get new" do
    get new_order_url
    assert_response :success
  end

  test "should create order" do
    assert_difference("Order.count") do
      post orders_url, params: { order: {} }
    end

    assert_redirected_to order_url(Order.last)
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
  end

  test "should get edit" do
    get edit_order_url(@order)
    assert_response :success
  end

  test "should update order" do
    patch order_url(@order), params: { order: {} }
    assert_redirected_to order_url(@order)
  end

  test "should destroy order" do
    assert_difference("Order.count", -1) do
      delete order_url(@order)
    end

    assert_redirected_to orders_url
  end

  test "should accept anonymous Mana Pool webhook payloads for new orders" do
    order_payload = {
      id: "f4b3b9c5-250e-4c3a-815d-6e41577f28e3",
      shipping_address: {
        name: "John Doe"
      },
      total_cents: 1100
    }

    fetch_called = false
    alert_called = false
    test_case = self

    fetch_service = Manapool::FetchOrdersService.singleton_class
    alert_service = MatrixAlerts::NewOrderService.singleton_class

    original_fetch_call = Manapool::FetchOrdersService.method(:call)
    original_alert_call = MatrixAlerts::NewOrderService.method(:call)
    original_allow_forgery_protection = ActionController::Base.allow_forgery_protection

    sign_out @user
    ActionController::Base.allow_forgery_protection = true

    fetch_service.send(:define_method, :call) do |fulfilled:|
      fetch_called = true
      test_case.assert_equal "all", fulfilled
    end

    alert_service.send(:define_method, :call) do |details|
      alert_called = true
      test_case.assert_instance_of Hash, details
      test_case.assert_equal "John Doe", details["shipping_address"]["name"]
      test_case.assert_equal 1100, details["total_cents"]
    end

    post orders_new_order_url, params: { order: order_payload }, as: :json

    assert fetch_called
    assert alert_called
    assert_response :ok
  ensure
    ActionController::Base.allow_forgery_protection = original_allow_forgery_protection
    fetch_service.send(:define_method, :call, original_fetch_call)
    alert_service.send(:define_method, :call, original_alert_call)
  end

  test "should return ok when Matrix alerting fails for new order webhook" do
    order_payload = {
      id: "f4b3b9c5-250e-4c3a-815d-6e41577f28e3",
      shipping_address: {
        name: "John Doe"
      },
      total_cents: 1100
    }

    fetch_called = false
    test_case = self

    fetch_service = Manapool::FetchOrdersService.singleton_class
    alert_service = MatrixAlerts::NewOrderService.singleton_class

    original_fetch_call = Manapool::FetchOrdersService.method(:call)
    original_alert_call = MatrixAlerts::NewOrderService.method(:call)
    original_allow_forgery_protection = ActionController::Base.allow_forgery_protection

    sign_out @user
    ActionController::Base.allow_forgery_protection = true

    fetch_service.send(:define_method, :call) do |fulfilled:|
      fetch_called = true
      test_case.assert_equal "all", fulfilled
    end

    alert_service.send(:define_method, :call) do |_details|
      raise MatrixSdk::MatrixNotAuthorizedError, "Invalid access token passed."
    end

    post orders_new_order_url, params: { order: order_payload }, as: :json

    assert fetch_called
    assert_response :ok
  ensure
    ActionController::Base.allow_forgery_protection = original_allow_forgery_protection
    fetch_service.send(:define_method, :call, original_fetch_call)
    alert_service.send(:define_method, :call, original_alert_call)
  end
end
