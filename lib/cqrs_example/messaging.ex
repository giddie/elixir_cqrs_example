defmodule CqrsExample.Messaging do
  @moduledoc false

  require Logger

  @event_processors Application.compile_env!(:cqrs_example, __MODULE__)
                    |> Keyword.fetch!(:listeners)
                    |> Keyword.values()
                    |> Enum.concat()

  # NOTE: Dispatching events is not atomic. Depending on requirements, this may be a serious
  # concern, since a failure in any event handler will result in a potentially inconsistent
  # application state. For an in-memory solution, it may be necessary to use Mnesia or another
  # in-memory database with transaction functionality.
  @spec dispatch_events([struct()]) :: :ok
  def dispatch_events(events) when is_list(events) do
    for event <- events, event_processor <- @event_processors do
      try do
        :ok = event_processor.handle_event(event)
      rescue
        e ->
          Logger.error(
            "Error handling event: #{Kernel.inspect(event)}\n" <>
              Exception.format(:error, e, __STACKTRACE__)
          )
      end
    end

    :ok
  end
end
