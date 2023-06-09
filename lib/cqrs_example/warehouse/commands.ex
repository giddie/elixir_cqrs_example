defmodule CqrsExample.Warehouse.Commands do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Views

  require Logger

  defmodule DomainConsistencyError do
    defexception [:message]
    @type t :: %__MODULE__{}
  end

  @spec increase_product_quantity(String.t(), pos_integer()) :: {:ok, [Messaging.Message.t()]}
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    {:ok,
     [
       %Messaging.Message{
         type: "Warehouse.Events.ProductQuantityIncreased",
         schema_version: 1,
         payload: %{
           sku: sku,
           quantity: quantity
         }
       }
     ]}
  end

  @spec ship_product_quantity(String.t(), pos_integer()) ::
          {:ok, [Messaging.Message.t()]} | {:error, DomainConsistencyError.t()}
  def ship_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    quantity_on_hand = Views.Products.get_quantity(sku)

    if quantity > quantity_on_hand do
      {:error, %DomainConsistencyError{message: "Insufficient quantity on hand."}}
    else
      {:ok,
       [
         %Messaging.Message{
           type: "Warehouse.Events.ProductQuantityShipped",
           schema_version: 1,
           payload: %{
             sku: sku,
             quantity: quantity
           }
         }
       ]}
    end
  end

  @spec notify_low_product_quantity(String.t(), non_neg_integer()) ::
          {:ok, [Messaging.Message.t()]}
  def notify_low_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) do
    Logger.warn("Low quantity of product #{sku}! #{quantity} remaining.")

    {:ok,
     [
       %Messaging.Message{
         type: "Warehouse.Events.NotifiedLowProductQuantity",
         schema_version: 1,
         payload: %{sku: sku}
       }
     ]}
  end
end
