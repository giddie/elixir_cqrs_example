defmodule CqrsExample.StateSupervisor do
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
        CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor
      ]
      |> concat_if(enable_test_event_processors?(), [
        CqrsExample.Test.EventProcessor,
        CqrsExample.Test.EventWatcher
      ])

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec enable_test_event_processors?() :: boolean()
  defp enable_test_event_processors?() do
    Application.get_env(:cqrs_example, __MODULE__, [])
    |> Keyword.get(:enable_test_event_processors, false)
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
