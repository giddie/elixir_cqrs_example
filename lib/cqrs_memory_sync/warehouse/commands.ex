defmodule CqrsMemorySync.Warehouse.Commands do
  @moduledoc false

  alias CqrsMemorySync.Warehouse.Events
  alias CqrsMemorySync.Warehouse.Views

  require Logger

  defmodule DomainConsistencyError do
    defexception [:message]
    @type t :: %__MODULE__{}
  end

  @type event :: struct()

  @spec increase_product_quantity(String.t(), pos_integer()) :: {:ok, [event()]}
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

  @spec ship_product_quantity(String.t(), pos_integer()) ::
          {:ok, [event()]} | {:error, DomainConsistencyError.t()}
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

  @spec notify_low_product_quantity(String.t(), non_neg_integer()) :: {:ok, [event()]}
  def notify_low_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) do
    Logger.warn("Low quantity of product #{sku}! #{quantity} remaining.")
    {:ok, [%Events.NotifiedLowProductQuantity{sku: sku}]}
  end
end
