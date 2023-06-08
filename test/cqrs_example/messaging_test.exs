defmodule CqrsExample.MessagingTest do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Events
  alias CqrsExample.Warehouse.Views

  alias CqrsExample.Test.EventProcessor
  alias CqrsExample.Test.EventWatcher

  use CqrsExample.DataCase, async: false

  defmodule ExampleEvent do
    @moduledoc false

    defstruct []
  end

  setup do
    CqrsExample.Application.reset_state()
  end

  test "dispatch_event" do
    :ok = Messaging.dispatch_events([%ExampleEvent{}])
    assert [%ExampleEvent{}] = EventWatcher.list_events()
  end

  test "dispatch_event: failing event handler" do
    # Events should be processed atomically across all handlers, ensuring a consistent state if
    # one of the handlers fails.

    :ok = EventProcessor.fail_next_event()

    try do
      [
        %Events.ProductQuantityIncreased{
          sku: "abc123",
          quantity: 30
        }
      ]
      |> Messaging.dispatch_events()
    rescue
      _e -> :ok
    end

    assert [] = Views.Products.list()
  end
end
