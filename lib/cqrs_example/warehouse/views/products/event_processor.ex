defmodule CqrsExample.Warehouse.Views.Products.EventProcessor do
  @moduledoc """
  Watches event messages relating to warehouse product quantity and updates the view's internal
  state accordingly.
  """

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Views.Products

  @behaviour Messaging.MessageHandler

  @impl Messaging.MessageHandler
  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    Products.adjust_quantity(sku, quantity)
  end

  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityShipped",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    Products.adjust_quantity(sku, -quantity)
  end

  def handle_message(_message) do
    :ok
  end
end
