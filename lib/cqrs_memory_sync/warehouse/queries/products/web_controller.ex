defmodule CqrsMemorySync.Warehouse.Queries.Products.WebController do
  use CqrsMemorySyncWeb, :controller

  def index(%Plug.Conn{} = conn, %{} = _params) do
    json(conn, [])
  end
end
