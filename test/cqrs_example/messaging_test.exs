defmodule CqrsExample.MessagingTest do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Events
  alias CqrsExample.Warehouse.Views

  alias CqrsExample.Test.EventProcessor
  alias CqrsExample.Test.EventWatcher

  use ExUnit.Case, async: false

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

  @tag :skip
  test "dispatch_event: failing event handler" do
    # NOTE: Events should be processed atomically across all handlers, ensuring a consistent state
    # if one of the handlers fails. This test shows that this issue is not yet handled in this
    # implementation.

    :ok = EventProcessor.fail_next_event()

    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 30
      }
    ]
    |> Messaging.dispatch_events()

    assert [] = Views.Products.Agent.list()
  end
end
