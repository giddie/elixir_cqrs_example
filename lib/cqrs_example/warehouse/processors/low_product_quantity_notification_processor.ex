defmodule CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor do
  @moduledoc false

  alias CqrsExample.Warehouse.Events
  alias CqrsExample.Warehouse.Commands
  alias CqrsExample.Messaging

  use Agent

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    Agent.start_link(
      fn -> %{} end,
      name: __MODULE__
    )
  end

  @spec handle_event(struct()) :: :ok | {:error, any()}
  def handle_event(%Events.ProductQuantityIncreased{} = event) do
    Agent.update(__MODULE__, fn %{} = state ->
      Map.update(state, event.sku, event.quantity, &(&1 + event.quantity))
    end)
  end

  def handle_event(%Events.ProductQuantityShipped{} = event) do
    Agent.get_and_update(__MODULE__, fn %{} = state ->
      Map.get_and_update(state, event.sku, fn
        nil ->
          {0, 0}

        current_quantity ->
          new_quantity = current_quantity - event.quantity
          {new_quantity, new_quantity}
      end)
    end)
    |> Kernel.then(fn new_quantity ->
      if new_quantity <= 5 do
        {:ok, events} = Commands.notify_low_product_quantity(event.sku, new_quantity)
        :ok = Messaging.dispatch_events(events)
      end
    end)

    :ok
  end

  def handle_event(_event) do
    :ok
  end
end
