defmodule CqrsExample.Warehouse.Commands.WebControllerTest do
  use CqrsExampleWeb.ConnCase

  alias CqrsExample.Messaging
  alias CqrsExample.Warehouse.Events
  alias CqrsExample.Test.EventWatcher

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

    assert [%Events.ProductQuantityIncreased{sku: "abc123", quantity: 50}] =
             EventWatcher.list_events()
  end

  test "ship_quantity: unknown product", %{conn: conn} do
    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 40})
    assert response(conn, 400) == "Insufficient quantity on hand."

    assert [] = EventWatcher.list_events()
  end

  test "ship_quantity: insufficient quantity", %{conn: conn} do
    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 10
      }
    ]
    |> Messaging.dispatch_events()

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 11})
    assert response(conn, 400) == "Insufficient quantity on hand."

    assert [%Events.ProductQuantityIncreased{sku: "abc123", quantity: 10}] =
             EventWatcher.list_events()
  end

  test "ship_quantity: all of the available quantity", %{conn: conn} do
    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 10
      }
    ]
    |> Messaging.dispatch_events()

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 10})
    assert response(conn, 200) == ""

    assert [
             %Events.ProductQuantityIncreased{sku: "abc123", quantity: 10},
             %Events.NotifiedLowProductQuantity{sku: "abc123"},
             %Events.ProductQuantityShipped{sku: "abc123", quantity: 10}
           ] = EventWatcher.list_events()
  end

  test "ship_quantity: not quite all, but enough to trigger a notification", %{conn: conn} do
    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 10
      }
    ]
    |> Messaging.dispatch_events()

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 5})
    assert response(conn, 200) == ""

    assert [
             %Events.ProductQuantityIncreased{sku: "abc123", quantity: 10},
             %Events.NotifiedLowProductQuantity{sku: "abc123"},
             %Events.ProductQuantityShipped{sku: "abc123", quantity: 5}
           ] = EventWatcher.list_events()
  end

  test "ship_quantity: not enough to trigger a notification", %{conn: conn} do
    [
      %Events.ProductQuantityIncreased{
        sku: "abc123",
        quantity: 50
      }
    ]
    |> Messaging.dispatch_events()

    conn = post(conn, ~p"/warehouse/products/abc123/ship_quantity", %{quantity: 40})
    assert response(conn, 200) == ""

    assert [
             %Events.ProductQuantityIncreased{sku: "abc123", quantity: 50},
             %Events.ProductQuantityShipped{sku: "abc123", quantity: 40}
           ] = EventWatcher.list_events()
  end
end
