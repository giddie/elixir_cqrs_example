defmodule CqrsExample.Warehouse.Commands do
  @moduledoc false

  alias __MODULE__.State
  alias CqrsExample.Messaging

  require Logger

  defmodule InsufficientQuantityOnHandError do
    defexception []
    @type t :: %__MODULE__{}

    @impl Exception
    def message(_self), do: "Insufficient quantity on hand."
  end

  @spec increase_product_quantity(String.t(), pos_integer()) :: {:ok, [Messaging.Message.t()]}
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    :ok = State.adjust_product_quantity(sku, quantity)

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
          {:ok, [Messaging.Message.t()]} | {:error, InsufficientQuantityOnHandError.t()}
  def ship_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    with :ok <- State.adjust_product_quantity(sku, -quantity) do
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
