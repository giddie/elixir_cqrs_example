defmodule CqrsExample.Warehouse.Views.ProductsTest do
  @moduledoc false

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Views.Products
  alias CqrsExample.Warehouse.Views.Products.EventProcessor

  use CqrsExample.DataCase, async: true

  test "list: no products" do
    assert [] = Products.list()
  end

  test "list" do
    [
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{
          "sku" => "abc123",
          "quantity" => 30
        }
      },
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityShipped",
        schema_version: 1,
        payload: %{
          "sku" => "abc123",
          "quantity" => 20
        }
      }
    ]
    |> Messaging.unicast_messages_sync!(EventProcessor)

    assert [
             %Products.Product{sku: "abc123", quantity: 10}
           ] = Products.list()
  end
end
