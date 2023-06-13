defmodule CqrsExample.Messaging.MessageProcessingBroadway do
  @moduledoc false

  alias CqrsExample
  alias CqrsExample.Messaging
  alias CqrsExample.Messaging.SerializedMessage

  use Broadway

  defmodule Context do
    @moduledoc false

    @enforce_keys [:message_processor_module]
    defstruct @enforce_keys
  end

  @spec start_link(module()) :: Broadway.on_start()
  def start_link(message_processor_module) when is_atom(message_processor_module) do
    {queue_name, declare_opts} =
      if use_durable_queues?() do
        base_name =
          Atom.to_string(message_processor_module)
          |> String.replace_prefix("#{CqrsExample}.", "")

        {"#{queue_prefix()}_#{base_name}", durable: true}
      else
        {UUID.uuid4(), auto_delete: true}
      end

    # Declare the queue synchronously instead of letting broadway create it for us asynchronously,
    # to ensure the queue is ready to receive messages before we consider this process started.
    {:ok, channel} = AMQP.Application.get_channel(:dispatch)
    {:ok, %{}} = AMQP.Queue.declare(channel, queue_name, declare_opts)
    :ok = AMQP.Queue.bind(channel, queue_name, Messaging.exchange_name())

    producer_opts = [
      queue: queue_name,
      on_failure: :reject_and_requeue,
      qos: [prefetch_count: 1],
      metadata: [:headers]
    ]

    Broadway.start_link(__MODULE__,
      name: :"#{__MODULE__}_#{message_processor_module}",
      context: %Context{message_processor_module: message_processor_module},
      producer: [
        module: {BroadwayRabbitMQ.Producer, producer_opts}
      ],
      processors: [
        default: [concurrency: 1]
      ]
    )
  end

  @impl Broadway
  def handle_message(_processor, %Broadway.Message{} = message, %Context{} = context) do
    require Logger

    message.metadata.headers
    |> Enum.into(%{}, fn
      {name, _type, value} when is_binary(name) -> {name, value}
    end)
    |> Kernel.then(fn %{"Type" => type, "Schema Version" => schema_version} ->
      %SerializedMessage{
        type: type,
        schema_version: schema_version,
        payload: message.data
      }
      |> Messaging.deserialize_message!()
    end)
    |> context.message_processor_module.handle_message()

    message
  end

  @spec use_durable_queues?() :: boolean()
  defp use_durable_queues?() do
    Application.fetch_env!(:cqrs_example, Messaging)
    |> Keyword.get(:use_durable_queues, true)
  end

  @spec queue_prefix() :: String.t()
  defp queue_prefix() do
    Application.fetch_env!(:cqrs_example, Messaging)
    |> Keyword.fetch!(:queue_prefix)
  end
end
