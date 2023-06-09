defmodule CqrsExample.Warehouse.Commands.WebControllerTest do
  use CqrsExampleWeb.ConnCase
  use AssertEventually, timeout: 1_000, interval: 50

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Views
  alias CqrsExample.Test.MessageWatcher

  setup do
    CqrsExample.Application.reset_state()
  end

  test "increase_quantity: bad params", %{conn: conn} do
    conn = post(conn, ~p"/warehouse/products/abc123/increase_quantity", %{})
    assert response(conn, 400) == ""

    conn = post(conn, ~p"/warehouse/products/abc123/increase_quantity", %{quantity: 0})
    assert response(conn, 400) == ""

    conn = post(conn, ~p"/warehouse/products/abc123/increase_quantity", %{quantity: -1})
    assert response(conn, 400) == ""
  end

  test "increase_quantity", %{conn: conn} do
    conn = post(conn, ~p"/warehouse/products/abc123/increase_quantity", %{quantity: 50})
    assert response(conn, 200) == ""

    assert_eventually(
      [
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityIncreased",
          schema_version: 1,
          payload: %{"sku" => "abc123", "quantity" => 50}
        }
      ] = MessageWatcher.list_messages()
    )
  end

  test "ship_quantity: unknown product", %{conn: conn} do
    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 40})
    assert response(conn, 400) == "Insufficient quantity on hand."

    Process.sleep(1_000)
    assert [] = MessageWatcher.list_messages()
  end

  describe "with a quantity of 10 on hand" do
    setup do
      [
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityIncreased",
          schema_version: 1,
          payload: %{
            sku: "abc123",
            quantity: 10
          }
        }
      ]
      |> Messaging.dispatch_events()

      # Wait until the product appears in the view.
      assert_eventually([%Views.Products.Product{}] = Views.Products.list())

      :ok
    end

    test "ship_quantity: insufficient quantity", %{conn: conn} do
      conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 11})
      assert response(conn, 400) == "Insufficient quantity on hand."

      assert_eventually(
        [
          %Messaging.Message{
            type: "Warehouse.Events.ProductQuantityIncreased",
            schema_version: 1,
            payload: %{"sku" => "abc123", "quantity" => 10}
          }
        ] = MessageWatcher.list_messages()
      )
    end

    test "ship_quantity: all of the available quantity", %{conn: conn} do
      conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 10})
      assert response(conn, 200) == ""

      assert_eventually(
        [
          %Messaging.Message{
            type: "Warehouse.Events.ProductQuantityIncreased",
            schema_version: 1,
            payload: %{"sku" => "abc123", "quantity" => 10}
          },
          %Messaging.Message{
            type: "Warehouse.Events.ProductQuantityShipped",
            schema_version: 1,
            payload: %{"sku" => "abc123", "quantity" => 10}
          },
          %Messaging.Message{
            type: "Warehouse.Events.NotifiedLowProductQuantity",
            schema_version: 1,
            payload: %{"sku" => "abc123"}
          }
        ] = MessageWatcher.list_messages()
      )
    end

    test "ship_quantity: not quite all, but enough to trigger a notification", %{conn: conn} do
      conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 5})
      assert response(conn, 200) == ""

      assert_eventually(
        [
          %Messaging.Message{
            type: "Warehouse.Events.ProductQuantityIncreased",
            schema_version: 1,
            payload: %{"sku" => "abc123", "quantity" => 10}
          },
          %Messaging.Message{
            type: "Warehouse.Events.ProductQuantityShipped",
            schema_version: 1,
            payload: %{"sku" => "abc123", "quantity" => 5}
          },
          %Messaging.Message{
            type: "Warehouse.Events.NotifiedLowProductQuantity",
            schema_version: 1,
            payload: %{"sku" => "abc123"}
          }
        ] = MessageWatcher.list_messages()
      )
    end
  end

  test "ship_quantity: not enough to trigger a notification", %{conn: conn} do
    [
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{
          sku: "abc123",
          quantity: 50
        }
      }
    ]
    |> Messaging.dispatch_events()

    # Wait until the product appears in the view.
    assert_eventually([%Views.Products.Product{}] = Views.Products.list())

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 40})
    assert_eventually(response(conn, 200) == "")

    assert_eventually(
      [
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityIncreased",
          schema_version: 1,
          payload: %{"sku" => "abc123", "quantity" => 50}
        },
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityShipped",
          schema_version: 1,
          payload: %{"sku" => "abc123", "quantity" => 40}
        }
      ] = MessageWatcher.list_messages()
    )
  end

  test "ship_quantity: state reset + not enough to trigger a notification", %{conn: conn} do
    [
      %Messaging.Message{
        type: "Warehouse.Events.ProductQuantityIncreased",
        schema_version: 1,
        payload: %{sku: "abc123", quantity: 50}
      }
    ]
    |> Messaging.dispatch_events()

    # Wait until the product appears in the view.
    assert_eventually([%Views.Products.Product{}] = Views.Products.list())

    # Resetting the state could affect the detection of low product quantity. If, after a state
    # reset, the system were to assume the quantity was 0, we'd receive a notification when trying
    # to ship.
    CqrsExample.Application.reset_state()

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 40})
    assert response(conn, 200) == ""

    # Note that the first event is missing here due to the state reset.
    assert_eventually(
      [
        %Messaging.Message{
          type: "Warehouse.Events.ProductQuantityShipped",
          schema_version: 1,
          payload: %{"sku" => "abc123", "quantity" => 40}
        }
      ] = MessageWatcher.list_messages()
    )
  end
end
