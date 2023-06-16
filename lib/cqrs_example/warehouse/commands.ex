defmodule CqrsExample.Warehouse.Commands do
  @moduledoc """
  Commands that apply to the Warehouse domain context.
  """

  alias __MODULE__.State
  alias CqrsExample.Messaging
  alias CqrsExample.Repo

  require Logger

  defmodule InsufficientQuantityOnHandError do
    defexception []
    @type t :: %__MODULE__{}

    @impl Exception
    def message(_self), do: "Insufficient quantity on hand."
  end

  @messages %{
    product_quantity_increased: "Warehouse.Events.ProductQuantityIncreased",
    product_quantity_shipped: "Warehouse.Events.ProductQuantityShipped",
    notified_low_product_quantity: "Warehouse.Events.NotifiedLowProductQuantity"
  }

  @doc """
  Increases the available quantity of the product with the given SKU in the warehouse. If the
  product SKU was previously unknown, we simply assume the current quantity is 0.

  ## Broadcasts Messages
  * #{@messages[:product_quantity_increased]}
  """
  @spec increase_product_quantity(String.t(), pos_integer()) :: :ok
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    :ok = State.adjust_product_quantity(sku, quantity)

    Repo.transaction(fn ->
      [
        %Messaging.Message{
          type: @messages[:product_quantity_increased],
          schema_version: 1,
          payload: %{
            sku: sku,
            quantity: quantity
          }
        }
      ]
      |> Messaging.broadcast_messages!()
    end)

    :ok
  end

  @doc """
  Decreases the available quantity of the product with the given SKU in the warehouse by marking
  it as shipped.

  ## Broadcasts Messages
  * #{@messages[:product_quantity_shipped]}
  """
  @spec ship_product_quantity(String.t(), pos_integer()) ::
          :ok | {:error, InsufficientQuantityOnHandError.t()}
  def ship_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    Repo.transaction(fn ->
      State.adjust_product_quantity(sku, -quantity)
      |> case do
        :ok ->
          [
            %Messaging.Message{
              type: @messages[:product_quantity_shipped],
              schema_version: 1,
              payload: %{
                sku: sku,
                quantity: quantity
              }
            }
          ]
          |> Messaging.broadcast_messages!()

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Logs a message warning that the remaining quantity of a given product is low. This command
  doesn't check the quantity, it just logs the message and broadcasts a message when it's done.

  ## Broadcasts Messages
  * #{@messages[:notified_low_product_quantity]}
  """
  @spec notify_low_product_quantity(String.t(), non_neg_integer()) :: :ok
  def notify_low_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) do
    Repo.transaction(fn ->
      Logger.warn("Low quantity of product #{sku}! #{quantity} remaining.")

      :ok =
        [
          %Messaging.Message{
            type: @messages[:notified_low_product_quantity],
            schema_version: 1,
            payload: %{sku: sku}
          }
        ]
        |> Messaging.broadcast_messages!()
    end)

    :ok
  end
end
