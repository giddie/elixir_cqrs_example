defmodule CqrsExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CqrsExampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CqrsExample.PubSub},
      # Start Finch
      {Finch, name: CqrsExample.Finch},
      # Start the Endpoint (http/https)
      CqrsExampleWeb.Endpoint,
      CqrsExample.StateSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CqrsExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec reset_state() :: :ok
  def reset_state() do
    :ok = Supervisor.terminate_child(CqrsExample.Supervisor, CqrsExample.StateSupervisor)

    {:ok, _pid} = Supervisor.restart_child(CqrsExample.Supervisor, CqrsExample.StateSupervisor)

    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CqrsExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
