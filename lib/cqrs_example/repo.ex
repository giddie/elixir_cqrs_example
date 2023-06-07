defmodule CqrsExample.Repo do
  use Ecto.Repo,
    otp_app: :cqrs_example,
    adapter: Ecto.Adapters.Postgres
end
