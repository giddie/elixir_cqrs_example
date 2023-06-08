defmodule CqrsExample.Messaging do
  @moduledoc false

  alias CqrsExample.Repo
  require Logger

  @event_processors Application.compile_env!(:cqrs_example, __MODULE__)
                    |> Keyword.fetch!(:listeners)
                    |> Keyword.values()
                    |> Enum.concat()

  @spec dispatch_events([struct()]) :: :ok
  def dispatch_events(events) when is_list(events) do
    {:ok, _any} =
      Repo.transaction(fn ->
        for event <- events, event_processor <- @event_processors do
          :ok = event_processor.handle_event(event)
        end
      end)

    :ok
  end
end
