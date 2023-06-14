defmodule CqrsExample.Messaging.Supervisor do
  @moduledoc false

  alias CqrsExample.Messaging
  use Supervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      [
        Messaging.Avrora,
        Messaging.MessageProcessingSupervisor
      ]
      |> concat_if(not using_ecto_sandbox?(), [
        Messaging.OutboxProcessor
      ])

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec restart_message_processors() :: :ok
  def restart_message_processors() do
    child = Messaging.MessageProcessingSupervisor
    :ok = Supervisor.terminate_child(__MODULE__, child)
    {:ok, _pid} = Supervisor.restart_child(__MODULE__, child)

    :ok
  end

  @spec using_ecto_sandbox?() :: boolean()
  defp using_ecto_sandbox?() do
    Application.get_env(:cqrs_example, Messaging, [])
    |> Keyword.get(:using_ecto_sandbox, false)
  end

  @spec concat_if(list(), boolean(), list()) :: list()
  defp concat_if(list, condition, additional_list)
       when is_list(list) and
              is_boolean(condition) and
              is_list(additional_list) do
    if condition do
      list ++ additional_list
    else
      list
    end
  end
end
