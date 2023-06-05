defmodule CqrsMemorySync.Warehouse.Commands do
  @moduledoc false

  alias CqrsMemorySync.Messaging
  alias CqrsMemorySync.Warehouse.Events

  @spec increase_product_quantity(String.t(), pos_integer()) :: :ok | {:error, any()}
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    %Events.ProductQuantityIncreased{
      sku: sku,
      quantity: quantity
    }
    |> Messaging.dispatch_event()
  end
end