defmodule CqrsExample.Warehouse.Views.Products.WebController do
  use CqrsExampleWeb, :controller

  alias CqrsExample.Warehouse.Views.Products.Agent

  def index(%Plug.Conn{} = conn, %{} = _params) do
    products = Agent.list()
    json(conn, products)
  end
end
