defmodule CqrsExample.Messaging.Avrora do
  @moduledoc false

  use Avrora.Client,
    otp_app: :cqrs_example
end
