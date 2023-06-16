defmodule CqrsExample.Messaging.BroadcastListenerSupervisor do
  @moduledoc """
  Starts and supervises a `CqrsExample.Messaging.BroadcastListener` process for each
  "broadcast_listener" configured in the application config for `CqrsExample.Messaging`.
  """

  alias CqrsExample.Messaging
  alias CqrsExample.Messaging.BroadcastListener
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
      Enum.map(
        @broadcast_listeners,
        fn
          {message_handler_module, topics}
          when is_atom(message_handler_module) and is_list(topics) ->
            {BroadcastListener, {message_handler_module, topics}}
            |> Supervisor.child_spec(id: message_handler_module)

          spec ->
            raise "Badly-formed spec for broadcast listener: #{Kernel.inspect(spec)}. " <>
                    "Should be {message_handler_module, topics}."
        end
      )

    Supervisor.init(children, strategy: :one_for_one)
  end
end
