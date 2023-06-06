defmodule CqrsMemorySync.Warehouse.Views.Products.EventProcessor do
  @moduledoc false

  alias CqrsMemorySync.Warehouse.Events
  alias CqrsMemorySync.Warehouse.Views.Products.Agent

  @spec handle_event(struct()) :: :ok | {:error, any()}
  def handle_event(%Events.ProductQuantityIncreased{} = event) do
    Agent.adjust_quantity(event.sku, event.quantity)
  end

  def handle_event(%Events.ProductQuantityShipped{} = event) do
    Agent.adjust_quantity(event.sku, -event.quantity)
  end

  def handle_event(_event) do
    :ok
  end
end