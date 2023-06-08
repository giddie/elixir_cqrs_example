defmodule CqrsExample.Test.EventProcessor do
  @moduledoc false

  use Agent

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    Agent.start_link(
      fn -> false end,
      name: __MODULE__
    )
  end

  @spec fail_next_event() :: :ok
  def fail_next_event() do
    Agent.update(
      __MODULE__,
      fn _state -> true end
    )
  end

  @spec handle_event(struct()) :: :ok
  def handle_event(_event) do
    if Agent.get(__MODULE__, & &1) do
      Agent.update(__MODULE__, fn _state -> false end)
      raise "Deliberately failing in event handler."
    end

    :ok
  end
end
