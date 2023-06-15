defmodule CqrsExample.Warehouse.Commands do
  @moduledoc false

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

  @spec increase_product_quantity(String.t(), pos_integer()) :: :ok
  def increase_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    :ok = State.adjust_product_quantity(sku, quantity)

    Repo.transaction(fn ->
      [
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityIncreased",
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
              type: "Warehouse.Events.ProductQuantityShipped",
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

  @spec notify_low_product_quantity(String.t(), non_neg_integer()) :: :ok
  def notify_low_product_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) do
    Repo.transaction(fn ->
      Logger.warn("Low quantity of product #{sku}! #{quantity} remaining.")

      :ok =
        [
          %Messaging.Message{
            type: "Warehouse.Events.NotifiedLowProductQuantity",
            schema_version: 1,
            payload: %{sku: sku}
          }
        ]
        |> Messaging.broadcast_messages!()
    end)

    :ok
  end
end
