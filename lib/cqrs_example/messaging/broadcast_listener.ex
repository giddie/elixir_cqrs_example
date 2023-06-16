defmodule CqrsExample.Messaging.BroadcastListener do
  @moduledoc """
  Broadway pipeline intended to handle delivery of broadcast messages to a specific message
  handler module (that implements the `CqrsExample.Messaging.MessageHandler` behaviour).

  A queue will be declared in the broker that matches the name of the message handler this
  process is intended to serve, and the queue will be bound to the message broadcast exchange
  (`CqrsExample.Messaging.exchange_name/0`).

  In addition to the name of the message handling module, the argument to `start_link/1`
  includes a list of topics to which the queue should be subscribed. These correspond
  to routing keys, used when binding the queue to the exchange. Look up how topic
  exchanges work in RabbitMQ for an explanation of how this works under the hood, e.g.
  https://www.rabbitmq.com/tutorials/tutorial-five-spring-amqp.html. These can be used to limit
  the scope of broadcast messages delivered to the handler.

  Some config keys defined for `CqrsExample.Messaging` affect this module:

  * `use_durable_queues`: (default: `true`) Specifies that the queue defined for each message
    handler should be permanent, backed onto disk, so that it can survive broker crash or restart.
    If this is `false`, the queue will also be given a random name, and will be automatically
    deleted when the process terminates. This is useful for testing, where we want to ensure that
    queues are empty before each test.

  * `queue_prefix`: Added to the beginning of each declared queue name. This should be defined in
    `config/runtime.exs` (by an environment variable), so that a different prefix can be used for
    each instance of the app. This allows multiple versions of the app to connect to the same
    message broker, each with their own set of queues.

  ## See also
  * `CqrsExample.Messaging.BroadcastListenerSupervisor`
  """

  alias CqrsExample
  alias CqrsExample.Messaging
  alias CqrsExample.Messaging.SerializedMessage
  alias CqrsExample.Repo

  use Broadway

  defmodule Context do
    @moduledoc false

    @enforce_keys [:message_handler_module]
    defstruct @enforce_keys
  end

  defmodule BadlyFormedMessageError do
    defexception [:amqp_message]
    @type t :: %__MODULE__{}

    @impl Exception
    def message(%__MODULE__{} = struct) do
      "Badly-formed AMQP message: #{Kernel.inspect(struct.amqp_message)}"
    end
  end

  @spec start_link({module(), [String.t()]}) :: Broadway.on_start()
  def start_link({message_handler_module, topics})
      when is_atom(message_handler_module) and is_list(topics) do
    {queue_name, declare_opts} =
      if use_durable_queues?() do
        base_name =
          Atom.to_string(message_handler_module)
          |> String.replace_prefix("#{CqrsExample}.", "")

        {"#{queue_prefix()}_#{base_name}", durable: true}
      else
        {UUID.uuid4(), auto_delete: true}
      end

    # Declare the queue synchronously instead of letting broadway create it for us asynchronously,
    # to ensure the queue is ready to receive messages before we consider this process started.
    {:ok, channel} = AMQP.Application.get_channel(:dispatch)
    {:ok, %{}} = AMQP.Queue.declare(channel, queue_name, declare_opts)

    for topic <- topics do
      :ok =
        AMQP.Queue.bind(
          channel,
          queue_name,
          Messaging.exchange_name(),
          routing_key: topic
        )
    end

    producer_opts = [
      queue: queue_name,
      on_failure: :reject_and_requeue,
      qos: [prefetch_count: 1],
      metadata: [:routing_key]
    ]

    Broadway.start_link(__MODULE__,
      name: :"#{__MODULE__}_#{message_handler_module}",
      context: %Context{message_handler_module: message_handler_module},
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
    routing_key = Map.get(message.metadata, :routing_key, "")

    [type, schema_version_string] =
      Regex.run(~r{^(.+)\.v(\d+)$}, routing_key, capture: :all_but_first)

    {schema_version, ""} = Integer.parse(schema_version_string)

    deserialized_message =
      %SerializedMessage{
        type: type,
        schema_version: schema_version,
        payload: message.data
      }
      |> Messaging.deserialize_message!()

    Repo.transaction(fn ->
      context.message_handler_module.handle_message(deserialized_message)
      |> case do
        :ok -> :ok
        {:ok, _any} -> :ok
      end
    end)

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
