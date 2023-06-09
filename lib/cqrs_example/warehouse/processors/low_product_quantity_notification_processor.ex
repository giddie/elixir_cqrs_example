defmodule CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor do
  @moduledoc false

  alias CqrsExample.Warehouse.Commands
  alias CqrsExample.Warehouse.Views
  alias CqrsExample.Messaging

  use Agent

  @behaviour Messaging.MessageHandler

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    state =
      Views.Products.list()
      |> Enum.into(
        %{},
        fn %Views.Products.Product{} = product ->
          {product.sku, product.quantity}
        end
      )

    Agent.start_link(
      fn -> state end,
      name: __MODULE__
    )
  end

  @impl Messaging.MessageHandler
  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    Agent.update(__MODULE__, fn %{} = state ->
      Map.update(state, sku, quantity, &(&1 + quantity))
    end)
  end

  def handle_message(%Messaging.Message{
        type: "Warehouse.Events.ProductQuantityShipped",
        schema_version: 1,
        payload: %{"sku" => sku, "quantity" => quantity}
      }) do
    Agent.get_and_update(__MODULE__, fn %{} = state ->
      Map.get_and_update(state, sku, fn
        nil ->
          {0, 0}

        current_quantity ->
          new_quantity = current_quantity - quantity
          {new_quantity, new_quantity}
      end)
    end)
    |> Kernel.then(fn new_quantity ->
      if new_quantity <= 5 do
        {:ok, events} = Commands.notify_low_product_quantity(sku, new_quantity)
        :ok = Messaging.dispatch_events(events)
      end
    end)

    :ok
  end

  def handle_message(_event) do
    :ok
  end
end
