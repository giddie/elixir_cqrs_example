defmodule CqrsMemorySync.Test.EventWatcher do
  @moduledoc false

  require Logger

  use Agent

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    Agent.start_link(
      fn -> [] end,
      name: __MODULE__
    )
  end

  @spec handle_event(struct()) :: :ok | {:error, any()}
  def handle_event(event) do
    :ok = Logger.info("Event: #{Kernel.inspect(event)}")
    :ok = store_event(event)
  end

  @spec store_event(struct()) :: :ok
  def store_event(event) when is_struct(event) do
    Agent.update(
      __MODULE__,
      &List.insert_at(&1, -1, event)
    )
  end

  @spec list_events() :: [struct()]
  def list_events() do
    Agent.get(__MODULE__, & &1)
  end
end
