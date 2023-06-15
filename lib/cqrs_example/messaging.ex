defmodule CqrsExample.Messaging do
  @moduledoc false

  alias __MODULE__.Avrora
  alias __MODULE__.Message
  alias __MODULE__.OutboxMessage
  alias __MODULE__.OutboxProcessor
  alias __MODULE__.SerializedMessage
  alias CqrsExample.Repo

  require Ecto.Query

  @exchange_name Application.compile_env!(:cqrs_example, __MODULE__)
                 |> Keyword.fetch!(:exchange_name)
  @using_ecto_sandbox Application.compile_env!(:cqrs_example, __MODULE__)
                      |> Keyword.get(:using_ecto_sandbox, false)

  @spec exchange_name() :: String.t()
  def exchange_name(), do: @exchange_name

  defmodule SerializationError do
    defexception [:message, :message_struct]

    @type t :: %__MODULE__{}

    @impl Exception
    def message(%__MODULE__{} = struct) do
      "Failed to serialize message: #{Kernel.inspect(struct.message_struct)}. " <>
        Kernel.inspect(struct.message)
    end
  end

  defmodule Message do
    @moduledoc false
    @enforce_keys [:type, :schema_version, :payload]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            type: String.t(),
            schema_version: pos_integer(),
            payload: map()
          }
  end

  defmodule SerializedMessage do
    @moduledoc false
    @enforce_keys [:type, :schema_version, :payload]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            type: String.t(),
            schema_version: pos_integer(),
            payload: binary()
          }

    @spec to_message(t(), map()) :: Message.t()
    def to_message(%__MODULE__{} = message, %{} = payload) do
      %Message{
        type: message.type,
        schema_version: message.schema_version,
        payload: payload
      }
    end
  end

  defmodule MessageHandler do
    @moduledoc false
    @callback handle_message(Message.t()) :: :ok | {:ok, any()}
  end

  @spec normalize_messages!([Message.t()]) :: [Message.t()]
  def normalize_messages!(messages) when is_list(messages) do
    messages
    |> serialize_messages!()
    |> deserialize_messages!()
  end

  @spec normalize_messages([Message.t()]) ::
          {:ok, [Message.t()]} | {:error, [SerializationError.t()]}
  def normalize_messages(messages) when is_list(messages) do
    with {:ok, serialized_messages} <- serialize_messages(messages),
         {:ok, deserialized_messages} <- deserialize_messages(serialized_messages) do
      {:ok, deserialized_messages}
    end
  end

  @spec serialize_messages!([Message.t()]) :: [SerializedMessage.t()]
  def serialize_messages!(messages) when is_list(messages) do
    serialize_messages(messages)
    |> case do
      {:ok, messages} when is_list(messages) -> messages
      {:error, [%SerializationError{} = error | _others]} -> raise error
    end
  end

  @spec serialize_messages([Message.t()]) ::
          {:ok, [SerializedMessage.t()]} | {:error, [SerializationError.t()]}
  def serialize_messages(messages) when is_list(messages) do
    Enum.map(messages, &serialize_message/1)
    |> collect_results()
  end

  @spec serialize_message!(Message.t()) :: SerializedMessage.t()
  def serialize_message!(%Message{} = message) do
    serialize_message(message)
    |> case do
      {:ok, %SerializedMessage{} = message} -> message
      {:error, %SerializationError{} = error} -> raise error
    end
  end

  @spec serialize_message(Message.t()) ::
          {:ok, SerializedMessage.t()} | {:error, SerializationError.t()}
  defp serialize_message(%Message{} = message) do
    schema_name = "#{message.type}_v#{message.schema_version}"

    Avrora.encode_plain(message.payload, schema_name: schema_name)
    |> case do
      {:ok, encoded_payload} ->
        {:ok,
         %SerializedMessage{
           type: message.type,
           schema_version: message.schema_version,
           payload: encoded_payload
         }}

      {:error, reason} ->
        {:error,
         %SerializationError{
           message: reason,
           message_struct: message
         }}
    end
  end

  @spec deserialize_messages!([SerializedMessage.t()]) :: [Message.t()]
  def deserialize_messages!(messages) when is_list(messages) do
    deserialize_messages(messages)
    |> case do
      {:ok, messages} when is_list(messages) -> messages
      {:error, [%SerializationError{} = error | _others]} -> raise error
    end
  end

  @spec deserialize_messages([SerializedMessage.t()]) ::
          {:ok, [Message.t()]} | {:error, [SerializationError.t()]}
  def deserialize_messages(messages) when is_list(messages) do
    Enum.map(messages, &deserialize_message/1)
    |> collect_results()
  end

  @spec deserialize_message!(SerializedMessage.t()) :: Message.t()
  def deserialize_message!(%SerializedMessage{} = message) do
    deserialize_message(message)
    |> case do
      {:ok, %Message{} = message} -> message
      {:error, %SerializationError{} = error} -> raise error
    end
  end

  @spec deserialize_message(SerializedMessage.t()) ::
          {:ok, Message.t()} | {:error, SerializationError.t()}
  def deserialize_message(%SerializedMessage{} = message) do
    schema_name = "#{message.type}_v#{message.schema_version}"

    Avrora.decode_plain(message.payload, schema_name: schema_name)
    |> case do
      {:ok, payload} ->
        {:ok, SerializedMessage.to_message(message, payload)}

      {:error, reason} ->
        {:error,
         %SerializationError{
           message: reason,
           message_struct: message
         }}
    end
  end

  @spec unicast_messages_sync!([Message.t()], atom()) :: :ok
  def unicast_messages_sync!(messages, message_handler_module) do
    unicast_messages_sync(messages, message_handler_module)
    |> case do
      :ok -> :ok
      {:error, [%SerializationError{} = error | _rest]} -> raise error
    end
  end

  @spec unicast_messages_sync([Message.t()], atom()) :: :ok | {:error, [SerializationError.t()]}
  def unicast_messages_sync(messages, message_handler_module)
      when is_list(messages) and
             is_atom(message_handler_module) do
    with {:ok, messages} <- normalize_messages(messages) do
      Repo.transaction(fn ->
        for message <- messages do
          message_handler_module.handle_message(message)
          |> case do
            :ok -> :ok
            {:ok, _any} -> :ok
          end
        end
      end)

      :ok
    end
  end

  @spec broadcast_messages!([Message.t()]) :: :ok
  def broadcast_messages!(messages) do
    broadcast_messages(messages)
    |> case do
      :ok -> :ok
      {:error, [%SerializationError{} = error | _rest]} -> raise error
    end
  end

  @spec broadcast_messages([Message.t()]) :: :ok | {:error, [SerializationError.t()]}
  def broadcast_messages(messages) when is_list(messages) do
    with {:ok, messages} <- serialize_messages(messages) do
      for message <- messages do
        :ok = store_message_in_outbox(message)
      end

      if @using_ecto_sandbox do
        # The outbox processor will never receive a notification that these records have been
        # inserted, because its connection is outside the transaction that wraps the test, so we
        # need to tell it directly.
        :ok = OutboxProcessor.check_for_new_messages()
      end

      :ok
    end
  end

  @spec store_message_in_outbox(SerializedMessage.t()) :: :ok
  def store_message_in_outbox(%SerializedMessage{} = message) do
    if not Repo.in_transaction?() do
      raise "Messages stored in the outbox must be sent within a transaction."
    end

    {:ok, _record} =
      OutboxMessage.from_serialized_message(message)
      |> Repo.insert()

    :ok
  end

  @spec peek_at_outbox_messages(pos_integer()) :: [Message.t()]
  def peek_at_outbox_messages(limit \\ 10) do
    Ecto.Query.from(
      o in OutboxMessage,
      order_by: [asc: :id],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.map(&OutboxMessage.to_serialized_message/1)
    |> Enum.map(&deserialize_message!/1)
  end

  @spec process_outbox_batch() :: non_neg_integer()
  def process_outbox_batch(batch_size \\ 10) do
    Repo.transaction(fn ->
      Ecto.Query.from(
        o in OutboxMessage,
        order_by: [asc: :id],
        limit: ^batch_size,
        lock: "FOR UPDATE SKIP LOCKED"
      )
      |> Repo.all()
      |> process_outbox_messages()
    end)
    |> Kernel.then(fn
      {:ok, num_processed} -> num_processed
    end)
  end

  @spec process_outbox_messages([OutboxMessage.t()]) :: non_neg_integer()
  defp process_outbox_messages([]), do: 0

  defp process_outbox_messages(records) when is_list(records) do
    record_ids =
      Enum.map(records, fn %OutboxMessage{} = record ->
        :ok =
          OutboxMessage.to_serialized_message(record)
          |> amqp_publish_message(@exchange_name)

        record.id
      end)

    {num_records, nil} =
      Ecto.Query.from(o in OutboxMessage, where: o.id in ^record_ids)
      |> Repo.delete_all()

    num_records
  end

  @spec amqp_publish_message(SerializedMessage.t(), String.t()) :: :ok
  def amqp_publish_message(%SerializedMessage{} = message, exchange_name)
      when is_binary(exchange_name) do
    {:ok, chan} = AMQP.Application.get_channel(:dispatch)

    AMQP.Basic.publish(chan, exchange_name, "", message.payload,
      persistent: true,
      headers: [
        {"Type", :binary, message.type},
        {"Schema Version", :short, message.schema_version}
      ]
    )
  end

  @spec collect_results(Enum.t({:ok, any()} | {:error, any()})) ::
          {:ok, [any()]} | {:error, [any()]}
  defp collect_results(results) when is_list(results) do
    Enum.reduce(results, %{}, fn {result, value}, acc when result in [:ok, :error] ->
      Map.update(acc, result, [value], &[value | &1])
    end)
    |> case do
      %{error: reasons} -> {:error, reasons}
      %{ok: messages} -> {:ok, messages}
    end
    |> Kernel.then(fn
      {result, list} -> {result, Enum.reverse(list)}
    end)
  end
end
