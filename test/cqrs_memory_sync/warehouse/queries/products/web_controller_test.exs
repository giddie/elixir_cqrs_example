defmodule CqrsMemorySync.Warehouse.Queries.Products.WebControllerTest do
  use CqrsMemorySyncWeb.ConnCase

  test "index: no products", %{conn: conn} do
    conn = get(conn, ~p"/warehouse/products")
    assert json_response(conn, 200) == []
  end
end
