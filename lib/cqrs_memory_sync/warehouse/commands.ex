defmodule CqrsMemorySync.Warehouse.Commands do
  @moduledoc false

  alias CqrsMemorySync.Warehouse.Events
  alias CqrsMemorySync.Warehouse.Views

  defmodule DomainConsistencyError do
    defexception [:message]
    @type t :: %__MODULE__{}
  end

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
    quantity_on_hand = Views.Products.Agent.get_quantity(sku)

    if quantity > quantity_on_hand do
      {:error, %DomainConsistencyError{message: "Insufficient quantity on hand."}}
    else
      {:ok,
       [
         %Events.ProductQuantityShipped{
           sku: sku,
           quantity: quantity
         }
       ]}
    end
  end
end
