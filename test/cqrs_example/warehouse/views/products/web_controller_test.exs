defmodule CqrsExample.Warehouse.Views.Products.WebControllerTest do
  use CqrsExampleWeb.ConnCase
  use AssertEventually, timeout: 1_000, interval: 50

  alias CqrsExample.Messaging

  setup do
    CqrsExample.Application.reset_state()
  end

  test "index: no products", %{conn: conn} do
    conn = get(conn, ~p"/warehouse/products")
    assert json_response(conn, 200) == []
  end

  test "index", %{conn: conn} do
    [
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{
          sku: "abc123",
          quantity: 30
        }
      },
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityShipped",
        schema_version: 1,
        payload: %{
          sku: "abc123",
          quantity: 20
        }
      }
    ]
    |> Messaging.dispatch_events()

    assert_eventually(
      get(conn, ~p"/warehouse/products")
      |> json_response(200) ==
        [
          %{"sku" => "abc123", "quantity" => 10}
        ]
    )
  end
end
