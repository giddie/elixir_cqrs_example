defmodule CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessorTest do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor

  use CqrsExample.DataCase, async: true

  @message_handler LowProductQuantityNotificationProcessor

  @spec increased_by(pos_integer()) :: Messaging.Message.t()
  defp increased_by(quantity) do
    %Messaging.Message{
      type: "Warehouse.Events.ProductQuantityIncreased",
      schema_version: 1,
      payload: %{
        sku: "abc123",
        quantity: quantity
      }
    }
  end

  @spec shipped(pos_integer()) :: Messaging.Message.t()
  defp shipped(quantity) do
    %Messaging.Message{
      type: "Warehouse.Events.ProductQuantityShipped",
      schema_version: 1,
      payload: %{
        sku: "abc123",
        quantity: quantity
      }
    }
  end

  @spec handle_messages([Messaging.Message.t()]) :: :ok
  defp handle_messages(messages) do
    Messaging.unicast_messages_sync!(messages, @message_handler)
  end

  test "ProductQuantityIncreased" do
    handle_messages([increased_by(10)])
    assert 10 = LowProductQuantityNotificationProcessor.get_quantity("abc123")
    assert [] = Messaging.peek_at_outbox_messages()

    handle_messages([shipped(4)])
    assert 6 = LowProductQuantityNotificationProcessor.get_quantity("abc123")
    assert [] = Messaging.peek_at_outbox_messages()

    handle_messages([shipped(1)])
    assert 5 = LowProductQuantityNotificationProcessor.get_quantity("abc123")

    assert [
             %CqrsExample.Messaging.Message{
               type: "Warehouse.Events.NotifiedLowProductQuantity",
               schema_version: 1,
               payload: %{"sku" => "abc123"}
             }
           ] = Messaging.peek_at_outbox_messages()
  end
end
