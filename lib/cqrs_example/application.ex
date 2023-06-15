defmodule CqrsExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        CqrsExampleWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: CqrsExample.PubSub},
        CqrsExample.Repo,
        # Start Finch
        {Finch, name: CqrsExample.Finch},
        # Start the Endpoint (http/https)
        CqrsExampleWeb.Endpoint,
        CqrsExample.Messaging.Avrora,
        CqrsExample.StateSupervisor
      ]
      |> concat_if(start_messaging?(), [
        CqrsExample.Messaging.BroadcastSupervisor
      ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CqrsExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec reset_state() :: :ok
  def reset_state() do
    child = CqrsExample.StateSupervisor
    :ok = Supervisor.terminate_child(CqrsExample.Supervisor, child)
    {:ok, _pid} = Supervisor.restart_child(CqrsExample.Supervisor, child)

    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CqrsExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @spec start_messaging?() :: boolean()
  defp start_messaging?() do
    Application.get_env(:cqrs_example, __MODULE__, [])
    |> Keyword.get(:start_messaging, true)
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
