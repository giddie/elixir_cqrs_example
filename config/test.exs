import Config

config :cqrs_memory_sync, CqrsMemorySync.StateSupervisor, enable_test_event_watcher: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cqrs_memory_sync, CqrsMemorySyncWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6thWGIqPNpXnRa06BB4928PCcpMW5GrSxuizWxXA81XMcguTFPbvLixGFNn6WgrD",
  server: false

# In test we don't send emails.
config :cqrs_memory_sync, CqrsMemorySync.Mailer, adapter: Swoosh.Adapters.Test

config :cqrs_memory_sync, CqrsMemorySync.Messaging,
  listeners: [
    environment_specific: [
      CqrsMemorySync.Test.EventWatcher
    ]
  ]

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
# config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
