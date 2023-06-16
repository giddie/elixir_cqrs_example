defmodule CqrsExample.Messaging.Avrora do
  @moduledoc """
  Private instance of Avrora, used for serialization and deserialization of messages in Avro
  format.
  """

  use Avrora.Client,
    otp_app: :cqrs_example
end
