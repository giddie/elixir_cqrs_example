defmodule CqrsExample.Warehouse.Commands.WebController do
  @moduledoc """
  Phoenix Web Controller to handle commands for the Warehouse domain context.
  """

  alias CqrsExample.Warehouse.Commands

  use CqrsExampleWeb, :controller

  def increase_quantity(%Plug.Conn{} = conn, %{"sku" => sku, "quantity" => quantity})
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    :ok = Commands.increase_product_quantity(sku, quantity)
    resp(conn, 200, "")
  end

  def increase_quantity(%Plug.Conn{} = conn, %{} = _params) do
    resp(conn, 400, "")
  end

  def ship_quantity(%Plug.Conn{} = conn, %{"sku" => sku, "quantity" => quantity})
      when is_binary(sku) and
             is_integer(quantity) and quantity > 0 do
    Commands.ship_product_quantity(sku, quantity)
    |> case do
      :ok ->
        resp(conn, 200, "")

      {:error, %Commands.InsufficientQuantityOnHandError{} = reason} ->
        resp(conn, 400, Exception.message(reason))
    end
  end

  def ship_quantity(%Plug.Conn{} = conn, %{} = _params) do
    resp(conn, 400, "")
  end
end
