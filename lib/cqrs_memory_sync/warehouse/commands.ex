defmodule CqrsMemorySync.Warehouse.Commands do
  @moduledoc false

  alias CqrsMemorySync.Warehouse.Events

  @spec increase_product_quantity(String.t(), pos_integer()) ::
          {:ok, [struct()]} | {:error, any()}
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    {:ok,
     [
       %Events.ProductQuantityIncreased{
         sku: sku,
         quantity: quantity
       }
     ]}
  end

  @spec ship_product_quantity(String.t(), pos_integer()) :: {:ok, [struct()]} | {:error, any()}
  def ship_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    {:ok,
     [
       %Events.ProductQuantityShipped{
         sku: sku,
         quantity: quantity
       }
     ]}
  end
end
