defmodule CqrsMemorySync.Warehouse.Views.Products.Agent do
  @moduledoc false

  use Agent

  @type entry :: %{quantity: non_neg_integer()}

  @new_entry %{quantity: 0}

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    Agent.start_link(
      fn -> %{} end,
      name: __MODULE__
    )
  end

  @spec list() :: [%{sku: String.t(), quantity: non_neg_integer()}]
  def list() do
    Agent.get(__MODULE__, & &1)
    |> Enum.map(fn {sku, %{quantity: quantity}} ->
      %{sku: sku, quantity: quantity}
    end)
  end

  @spec get_quantity(String.t()) :: non_neg_integer()
  def get_quantity(sku) when is_binary(sku) do
    Agent.get(
      __MODULE__,
      &Map.get(&1, sku, @new_entry)
    )
    |> Map.fetch!(:quantity)
  end

  @spec adjust_quantity(String.t(), integer()) :: :ok
  def adjust_quantity(sku, quantity)
      when is_binary(sku) and
             is_integer(quantity) do
    Agent.update(
      __MODULE__,
      fn %{} = state ->
        state
        |> Map.put_new(sku, @new_entry)
        |> Kernel.update_in([sku, :quantity], &(&1 + quantity))
      end
    )
  end
end
