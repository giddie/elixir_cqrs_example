defmodule CqrsMemorySync.Warehouse.Views.Products.WebControllerTest do
  use CqrsMemorySyncWeb.ConnCase

  alias CqrsMemorySync.Messaging
  alias CqrsMemorySync.Warehouse.Views.Products.Agent
  alias CqrsMemorySync.Warehouse.Events

  setup do
    Agent.reset()
  end

  test "index: no products", %{conn: conn} do
    conn = get(conn, ~p"/warehouse/products")
    assert json_response(conn, 200) == []
  end

  test "index", %{conn: conn} do
    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 30
      },
      %Events.ProductQuantityShipped{
        sku: "abc123",
        quantity: 20
      }
    ]
    |> Messaging.dispatch_events()

    conn = get(conn, ~p"/warehouse/products")

    assert json_response(conn, 200) == [
             %{"sku" => "abc123", "quantity" => 10}
           ]
  end
end
