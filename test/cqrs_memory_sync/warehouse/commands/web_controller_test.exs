defmodule CqrsMemorySync.Warehouse.Commands.WebControllerTest do
  use CqrsMemorySyncWeb.ConnCase

  alias CqrsMemorySync.Warehouse.Events
  alias CqrsMemorySync.Test.EventWatcher

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
end