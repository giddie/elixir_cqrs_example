defmodule CqrsExample.Messaging.BroadcastSupervisor do
  @moduledoc false

  alias CqrsExample.Messaging
  use Supervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec stop(any(), timeout()) :: :ok
  def stop(reason \\ :normal, timeout \\ :infinity) do
    Supervisor.stop(__MODULE__, reason, timeout)
  end

  @impl Supervisor
  def init(_init_arg) do
    {:ok, channel} = AMQP.Application.get_channel(:dispatch)
    :ok = AMQP.Exchange.declare(channel, Messaging.exchange_name(), :fanout, durable: true)

    children = [
      Messaging.QueueProcessorSupervisor,
      Messaging.OutboxProcessor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
