class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]

  def pull_selected_orders
    order_ids = params[:order_ids] || []
    orders = Order.where(id: order_ids)

    orders.each do |order|
      order.pull_items
      order.update(status: "pulling")
    end

    redirect_to inventory_path
  end

  def grab_unfilled_manapool_orders
    Manapool::FetchOrdersService.call
    redirect_to orders_path
  end

  def grab_all_manapool_orders
    Manapool::FetchOrdersService.call(unfulfilled: false)
    redirect_to orders_path
  end

  # GET /orders or /orders.json
  def index
    if params[:hide_shipped_orders] == "1"
      @orders = Order.where.not(status: "shipped")
    else
      @orders = Order.all.order(placed_at: :desc)
    end
  end

  # GET /orders/1 or /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders or /orders.json
  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    @order.destroy!

    respond_to do |format|
      format.html { redirect_to orders_path, status: :see_other, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.fetch(:order, {})
    end
end
