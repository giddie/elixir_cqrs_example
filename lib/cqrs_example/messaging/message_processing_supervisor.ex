defmodule CqrsExample.Messaging.QueueProcessorSupervisor do
  @moduledoc """
  Starts and supervises a `CqrsExample.Messaging.QueueProcessor` process for each "broadcast
  listener" configured in the application config for `CqrsExample.Messaging`.
  """

  alias CqrsExample.Messaging
  alias CqrsExample.Messaging.QueueProcessor
  use Supervisor

  @broadcast_listeners Application.compile_env!(:cqrs_example, Messaging)
                       |> Keyword.fetch!(:broadcast_listeners)
                       |> Keyword.values()
                       |> Enum.concat()

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      Enum.map(@broadcast_listeners, fn message_handler_module ->
        {QueueProcessor, message_handler_module}
        |> Supervisor.child_spec(id: message_handler_module)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
