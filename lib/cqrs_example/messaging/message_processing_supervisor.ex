defmodule CqrsExample.Messaging.MessageProcessingSupervisor do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Messaging.MessageProcessingBroadway
  use Supervisor

  @message_processors Application.compile_env!(:cqrs_example, Messaging)
                      |> Keyword.fetch!(:listeners)
                      |> Keyword.values()
                      |> Enum.concat()

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      Enum.map(@message_processors, fn message_processor_module ->
        {MessageProcessingBroadway, message_processor_module}
        |> Supervisor.child_spec(id: message_processor_module)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
