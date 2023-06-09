ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(CqrsExample.Repo, :manual)
CqrsExample.Test.BroadwayEctoSandbox.attach(CqrsExample.Repo)
