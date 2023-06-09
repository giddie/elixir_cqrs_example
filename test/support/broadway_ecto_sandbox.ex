defmodule CqrsExample.Test.BroadwayEctoSandbox do
  @moduledoc false

  alias :telemetry, as: Telemetry

  @spec attach(Ecto.Repo.t()) :: :ok
  def attach(repo) do
    events = [
      [:broadway, :processor, :start],
      [:broadway, :batch_processor, :start]
    ]

    :ok =
      Telemetry.attach_many(
        {__MODULE__, repo},
        events,
        &__MODULE__.handle_event/4,
        %{repo: repo}
      )
  end

  @spec handle_event([atom(), ...], map(), map(), any()) :: any()
  def handle_event(_event_name, _event_measurement, %{messages: messages}, %{repo: repo}) do
    with [%Broadway.Message{metadata: %{headers: headers}} | _] <- messages do
      Enum.find(headers, fn {name, _type, _value} -> name == "Metadata" end)
      |> case do
        nil -> %{}
        {"Metadata", :binary, data} -> :erlang.binary_to_term(data)
      end
      |> Kernel.then(fn
        %{ecto_sandbox_pid: pid} -> Ecto.Adapters.SQL.Sandbox.allow(repo, pid, self())
        %{} -> :ok
      end)
    end

    :ok
  end
end
