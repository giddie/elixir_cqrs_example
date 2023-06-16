defmodule CqrsExample.Warehouse.Views.Products.WebController do
  @moduledoc """
  Phoenix Web Controller to handle queries for the Warehouse Products view.
  """

  use CqrsExampleWeb, :controller

  alias CqrsExample.Warehouse.Views.Products

  def index(%Plug.Conn{} = conn, %{} = _params) do
    products =
      Products.list()
      |> Enum.map(fn %Products.Product{} = product ->
        %{sku: product.sku, quantity: product.quantity}
      end)

    json(conn, products)
  end
end
