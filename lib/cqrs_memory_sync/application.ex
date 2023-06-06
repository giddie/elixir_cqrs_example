defmodule CqrsMemorySync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CqrsMemorySyncWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CqrsMemorySync.PubSub},
      # Start Finch
      {Finch, name: CqrsMemorySync.Finch},
      # Start the Endpoint (http/https)
      CqrsMemorySyncWeb.Endpoint,
      CqrsMemorySync.StateSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CqrsMemorySync.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec reset_state() :: :ok
  def reset_state() do
    :ok = Supervisor.terminate_child(CqrsMemorySync.Supervisor, CqrsMemorySync.StateSupervisor)

    {:ok, _pid} =
      Supervisor.restart_child(CqrsMemorySync.Supervisor, CqrsMemorySync.StateSupervisor)

    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CqrsMemorySyncWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
