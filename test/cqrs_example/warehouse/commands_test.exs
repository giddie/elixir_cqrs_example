defmodule CqrsExample.Warehouse.CommandsTest do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Commands
  alias CqrsExample.Warehouse.Commands.State

  use CqrsExample.DataCase, async: true

  test "increase_product_quantity" do
    assert 0 = State.get_product_quantity("abc123")
    assert :ok = Commands.increase_product_quantity("abc123", 10)
    assert 10 = State.get_product_quantity("abc123")

    assert [
             %Messaging.Message{
               type: "Warehouse.Events.ProductQuantityIncreased",
               schema_version: 1,
               payload: %{
                 "sku" => "abc123",
                 "quantity" => 10
               }
             }
           ] == Messaging.peek_at_outbox_messages()
  end

  test "ship_product_quantity: unknown product" do
    assert 0 = State.get_product_quantity("abc123")

    assert {:error, %Commands.InsufficientQuantityOnHandError{}} =
             Commands.ship_product_quantity("abc123", 10)

    assert 0 = State.get_product_quantity("abc123")
  end

  test "ship_product_quantity" do
    :ok = State.adjust_product_quantity("abc123", 10)
    assert 10 = State.get_product_quantity("abc123")

    assert :ok = Commands.ship_product_quantity("abc123", 5)
    assert 5 = State.get_product_quantity("abc123")

    assert :ok = Commands.ship_product_quantity("abc123", 5)
    assert 0 = State.get_product_quantity("abc123")

    assert [
             %Messaging.Message{
               type: "Warehouse.Events.ProductQuantityShipped",
               schema_version: 1,
               payload: %{
                 "sku" => "abc123",
                 "quantity" => 5
               }
             },
             %Messaging.Message{
               type: "Warehouse.Events.ProductQuantityShipped",
               schema_version: 1,
               payload: %{
                 "sku" => "abc123",
                 "quantity" => 5
               }
             }
           ] == Messaging.peek_at_outbox_messages()
  end

  test "notify_low_product_quantity" do
    assert :ok = Commands.notify_low_product_quantity("abc123", 10)

    assert [
             %Messaging.Message{
               type: "Warehouse.Events.NotifiedLowProductQuantity",
               schema_version: 1,
               payload: %{
                 "sku" => "abc123"
               }
             }
           ] == Messaging.peek_at_outbox_messages()
  end
end
