defmodule CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor do
  @moduledoc false

  alias __MODULE__.State
  alias CqrsExample.Messaging
  alias CqrsExample.Repo
  alias CqrsExample.Warehouse.Commands

  require Ecto.Query

  @behaviour Messaging.MessageHandler

  @impl Messaging.MessageHandler
  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    {:ok, _new_quantity} = adjust_quantity(sku, quantity)
  end

  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityShipped",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    {:ok, new_quantity} = adjust_quantity(sku, -quantity)

    if new_quantity <= 5 do
      {:ok, events} = Commands.notify_low_product_quantity(sku, new_quantity)
      :ok = Messaging.dispatch_events(events)
    end
  end

  def handle_message(_event) do
    :ok
  end

  @spec adjust_quantity(String.t(), integer()) :: {:ok, integer()}
  def adjust_quantity(sku, quantity) do
    Ecto.Query.from(p in State,
      where: p.sku == ^sku,
      update: [set: [quantity: p.quantity + ^quantity]],
      select: p.quantity
    )
    |> Repo.update_all([])
    |> case do
      {1, [new_quantity]} -> {:ok, new_quantity}
      {0, []} -> insert_new(sku, quantity)
    end
  end

  @spec insert_new(String.t(), integer()) :: {:ok, integer()}
  defp insert_new(sku, quantity) do
    {:ok, _record} =
      %State{
        sku: sku,
        quantity: quantity
      }
      |> Repo.insert()

    {:ok, quantity}
  end
end
