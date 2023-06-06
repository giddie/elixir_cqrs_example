defmodule CqrsMemorySync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        CqrsMemorySyncWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: CqrsMemorySync.PubSub},
        # Start Finch
        {Finch, name: CqrsMemorySync.Finch},
        # Start the Endpoint (http/https)
        CqrsMemorySyncWeb.Endpoint,
        CqrsMemorySync.Warehouse.Views.Products.Agent
      ]
      |> concat_if(enable_test_event_watcher?(), [
        CqrsMemorySync.Test.EventWatcher
      ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CqrsMemorySync.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CqrsMemorySyncWeb.Endpoint.config_change(changed, removed)
    :ok
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
