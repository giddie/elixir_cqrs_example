# Elixir CQRS Example - Persisted, Sync

This branch builds on the
[memory-sync](https://github.com/giddie/elixir_cqrs_example/tree/memory-sync)
branch, maintaining synchronous event dispatch, but stores application state in
Postgres. In addition to making data persistent, which is generally more useful,
this also makes it possible to use transactions to ensure atomic processing of
events - either all handlers process an event successfully, or the entire event
fails.

## Event Handler Configuration

Handlers are configured statically in `config/config.exs`:

```elixir
config :cqrs_example, CqrsExample.Messaging,
  listeners: [
    global: [
      CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor,
      CqrsExample.Warehouse.Views.Products.EventProcessor
    ]
  ]
```

Each of these modules will receive a copy of each event.

## Modules of Interest

* [`Messaging`](/lib/cqrs_example/messaging.ex)
* [`StateSupervisor`](/lib/cqrs_example/state_supervisor.ex)
* [`Warehouse.Commands`](/lib/cqrs_example/warehouse/commands.ex)
* [`Warehouse.Views.Products.EventProcessor`](/lib/cqrs_example/warehouse/views/products/event_processor.ex)
* [`Warehouse.Processors.LowProductQuantityNotificationProcessor`](/lib/cqrs_example/warehouse/processors/low_product_quantity_notification_processor.ex)
* [Tests](/test/cqrs_example)

## Considerations

### Ordering of Handlers

One of the advantages of synchronous event processing is that it makes it
possible to take shortcuts by leveraging the well-known order of execution for
the event processors.

An example here is the
[`LowProductQuantityNotificationProcessor`](/lib/cqrs_example/warehouse/processors/low_product_quantity_notification_processor.ex),
which calls `Views.Products.list()` when it starts up to populate its internal
state. If the messages were processed asynchronously, it would be unsafe to do
this, because the products view could not offer any guarantees that it is
up-to-date when the `LowProductQuantityNotificationProcessor` agent starts up.
