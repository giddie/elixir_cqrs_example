defmodule CqrsMemorySync.StateSupervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      [
        CqrsMemorySync.Warehouse.Views.Products.Agent,
        CqrsMemorySync.Warehouse.Processors.LowProductQuantityNotificationProcessor
      ]
      |> concat_if(enable_test_event_watcher?(), [
        CqrsMemorySync.Test.EventWatcher
      ])

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec enable_test_event_watcher?() :: boolean()
  defp enable_test_event_watcher?() do
    Application.get_env(:cqrs_memory_sync, __MODULE__, [])
    |> Keyword.get(:enable_test_event_watcher, false)
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
