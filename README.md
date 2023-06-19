# Elixir CQRS Example - Persisted, Async

This branch departs significantly from the design of the `*-sync` branches. The
introduction of asynchronous message handling means that we now need to deal
with **eventual-consistency**. Although commands are here still processed
synchronously, the events they generate take effect asynchronously.

This branch uses:
* [RabbitMQ](https://www.rabbitmq.com/) as a message broker
* [Avro](https://avro.apache.org/) for message serialisation
* The [Outbox Pattern](https://www.youtube.com/watch?v=u8fOnxAxKHk) for atomic
    event dispatch
* [Broadway](https://github.com/dashbitco/broadway) to handle incoming messages
    from RabbitMQ
* [AssertEventually](https://hexdocs.pm/assert_eventually/AssertEventually.html)
    to handle eventual consistency in end-to-end tests

![Async Messages](https://github.com/giddie/elixir_cqrs_example/blob/docs/design/async-messages.png?raw=true)

## Command State

We can no longer rely on the product view to be up-to-date when processing a
command, so the "command" side of the system (the C from CQRS) now needs to
maintain its own independent state, which is the model that maintains
consistency of the aggregate in our domain model.

In fact at this point, there are three components that need to store their
state:

* Aggregate model (our domain model, used by commands to ensure logical
    consistency).
* Products View
* Low Product Quantity Notifier

None of these can rely on the state of the others being up-to-date, due to the
asynchronous nature of the system. So they each need to keep track of their own
state. This may seem like a lot of duplication, but that's really only because
this is such a simple example.

## Message Handler Configuration

Handlers are configured statically in `config/config.exs`:

```elixir
config :cqrs_example, CqrsExample.Messaging,
  exchange_name: "messaging",
  broadcast_listeners: [
    global: [
      {CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor,
       ["Warehouse.Events.#"]},
      {CqrsExample.Warehouse.Views.Products.EventProcessor, ["Warehouse.Events.#"]}
    ]
  ]
```

This is also where we can configure the name of the exchange used in RabbitMQ,
and each message handler can be configured to receive only the events it's
interested in, to avoid unnecessary routing of messages.

## Modules of Interest

* [`Messaging`](/lib/cqrs_example/messaging.ex)
* [`Messaging.OutboxProcessor`](/lib/cqrs_example/messaging/outbox_processor.ex)
* [`Messaging.BroadcastListener`](/lib/cqrs_example/messaging/broadcast_listener.ex)
* [`Warehouse.Commands`](/lib/cqrs_example/warehouse/commands.ex)
* [`Warehouse.Views.Products.EventProcessor`](/lib/cqrs_example/warehouse/views/products/event_processor.ex)
* [`Warehouse.Processors.LowProductQuantityNotificationProcessor`](/lib/cqrs_example/warehouse/processors/low_product_quantity_notification_processor.ex)
* [Avro Schemas](/priv/schemas/Warehouse/Events/)
* [Tests](/test/cqrs_example)

## Considerations

### Async Tests

End-to-end testing becomes difficult due to the eventual consistency we've
introduced, so
[AssertEventually](https://hexdocs.pm/assert_eventually/AssertEventually.html)
has been added to retry assertions for a time interval before failing. This is
probably not particularly efficient, so end-to-end tests should be kept to a
minimum at this point.

But thanks to the fact that messages are staged in the Outbox, we can safely
[test that commands emit the correct
events](/test/cqrs_example/warehouse/commands_test.exs), and introspect their
internal state, in `async` tests. The message never reaches RabbitMQ. This is a
much more efficient way to test each component.

The `OutboxProcessor` needs access to the database, which means it
cannot be launched in the test environment, where access to the database is
sandboxed for each test process. So the [`DataCase`](/test/support/data_case.ex)
module takes care of starting the whole message broadcasting system for us
([`Messaging.BroadcastSupervisor`](/lib/cqrs_example/messaging/broadcast_supervisor.ex))
only if `async: false`, in which case we're running the database in [shared
mode](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html#module-shared-mode).
