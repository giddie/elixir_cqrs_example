defmodule CqrsExample.Test.MessageWatcher do
  @moduledoc false

  alias CqrsExample.Messaging

  require Logger

  use Agent

  @behaviour Messaging.MessageHandler

  @spec start_link(any()) :: Agent.on_start()
  def start_link(_initial_value) do
    Agent.start_link(
      fn -> [] end,
      name: __MODULE__
    )
  end

  @impl Messaging.MessageHandler
  def handle_message(%Messaging.Message{} = message) do
    :ok = Logger.info("Message: #{Kernel.inspect(message)}")
    :ok = store_message(message)
  end

  @spec store_message(Messaging.Message.t()) :: :ok
  def store_message(%Messaging.Message{} = message) do
    Agent.update(
      __MODULE__,
      &List.insert_at(&1, -1, message)
    )
  end

  @spec list_messages() :: [struct()]
  def list_messages() do
    Agent.get(__MODULE__, & &1)
  end
end
