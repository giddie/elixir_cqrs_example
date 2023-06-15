import Config

config :cqrs_example, CqrsExample.Application, start_messaging: false

config :cqrs_example, CqrsExample.StateSupervisor, enable_test_message_processors: true

config :cqrs_example, CqrsExample.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cqrs_example_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cqrs_example, CqrsExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6thWGIqPNpXnRa06BB4928PCcpMW5GrSxuizWxXA81XMcguTFPbvLixGFNn6WgrD",
  server: false

# In test we don't send emails.
config :cqrs_example, CqrsExample.Mailer, adapter: Swoosh.Adapters.Test

config :cqrs_example, CqrsExample.Messaging,
  exchange_name: "test.messaging",
  using_ecto_sandbox: true,
  use_durable_queues: false,
  listeners: [
    environment_specific: [
      CqrsExample.Test.MessageWatcher
    ]
  ]

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
# config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
