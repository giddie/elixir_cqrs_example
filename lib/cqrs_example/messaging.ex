defmodule CqrsExample.Messaging do
  @moduledoc false

  alias __MODULE__.Avrora
  alias __MODULE__.Message
  alias __MODULE__.SerializedMessage
  require Logger

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
    @callback handle_message(Message.t()) :: :ok
  end

  @spec init() :: :ok
  def init() do
    exchange_name =
      Application.get_env(:cqrs_example, __MODULE__)
      |> Keyword.fetch!(:exchange_name)

    {:ok, channel} = AMQP.Application.get_channel(:dispatch)
    :ok = AMQP.Exchange.declare(channel, exchange_name, :fanout, durable: true)
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
    |> Enum.reduce(%{}, fn {result, value}, acc when result in [:ok, :error] ->
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

  @spec dispatch_events([Message.t()] | [SerializedMessage.t()]) ::
          :ok | {:error, [SerializationError.t()]}
  def dispatch_events([]), do: :ok

  def dispatch_events([%Message{} | _messages_tail] = messages) do
    with {:ok, events} <- serialize_messages(messages) do
      dispatch_events(events)
    end
  end

  def dispatch_events([%SerializedMessage{} | messages_tail] = messages) do
    {:ok, chan} = AMQP.Application.get_channel(:dispatch)

    true = Enum.all?(messages_tail, &Kernel.match?(%SerializedMessage{}, &1))

    metadata_header =
      if @using_ecto_sandbox do
        metadata = %{ecto_sandbox_pid: self()}
        [{"Metadata", :binary, :erlang.term_to_binary(metadata)}]
      else
        []
      end

    for %SerializedMessage{} = message <- messages do
      AMQP.Basic.publish(chan, @exchange_name, "", message.payload,
        persistent: true,
        headers:
          [
            {"Type", :binary, message.type},
            {"Schema Version", :short, message.schema_version}
          ] ++ metadata_header
      )
    end

    :ok
  end
end
