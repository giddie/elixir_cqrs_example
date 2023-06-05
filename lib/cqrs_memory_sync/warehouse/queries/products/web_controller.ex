defmodule CqrsMemorySync.Warehouse.Queries.Products.WebController do
  use CqrsMemorySyncWeb, :controller

  alias CqrsMemorySync.Warehouse.Queries.Products.Agent

  def index(%Plug.Conn{} = conn, %{} = _params) do
    products = Agent.list()
    json(conn, products)
  end
end
