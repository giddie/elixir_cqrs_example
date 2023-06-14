defmodule CqrsExample.Messaging.OutboxMessage do
  @moduledoc false

  alias __MODULE__, as: Self
  alias CqrsExample.Messaging.SerializedMessage

  use Ecto.Schema

  @schema_prefix "messaging"
  schema "outbox_messages" do
    field(:type, :string)
    field(:schema_version, :integer)
    field(:payload, :binary)
    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  @type t :: %Self{
          type: String.t(),
          schema_version: pos_integer(),
          payload: binary(),
          inserted_at: DateTime.t() | nil
        }

  @spec from_serialized_message(SerializedMessage.t()) :: Self.t()
  def from_serialized_message(%SerializedMessage{} = message) do
    %Self{
      type: message.type,
      schema_version: message.schema_version,
      payload: message.payload
    }
  end

  @spec to_serialized_message(Self.t()) :: SerializedMessage.t()
  def to_serialized_message(%Self{} = self) do
    %SerializedMessage{
      type: self.type,
      schema_version: self.schema_version,
      payload: self.payload
    }
  end
end
