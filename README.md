# Elixir CQRS Example - Memory, Sync

This branch uses synchronous event dispatch, and stores application state in
memory. This approach could be useful in applications that need a very low
latency, can load a state from some external source on startup, or where
long-lived state is not particularly important.

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

### Errors and Transactions

Using Agents for storage is easy and simple, but raises some significant
problems with error-handling. If something goes wrong in one event handler, the
application state may become inconsistent, since some of the handlers have
processed the event and others have not. If this is a concern, it would be
better to use an in-memory database that supports transactions, such as Mnesia.

### Ordering of Handlers

One of the advantages of synchronous event processing is that it makes it
possible to take shortcuts by leveraging the well-known order of execution for
the event processors. For instance, it's possible for one event handler to query
data updated by another event handler, so long as it is clearly-defined that the
second event handler processes its events first.
