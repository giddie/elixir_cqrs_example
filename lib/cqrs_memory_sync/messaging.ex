defmodule CqrsMemorySync.Messaging do
  @moduledoc false

  require Logger

  @event_processors Application.compile_env!(:cqrs_memory_sync, __MODULE__)
                    |> Keyword.fetch!(:listeners)
                    |> Keyword.values()
                    |> Enum.concat()

  @spec dispatch_event(struct()) :: :ok
  def dispatch_event(event) when is_struct(event) do
    for event_processor <- @event_processors do
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
