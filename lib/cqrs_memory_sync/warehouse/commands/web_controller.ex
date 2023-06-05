defmodule CqrsMemorySync.Warehouse.Commands.WebController do
  @moduledoc false

  alias CqrsMemorySync.Warehouse.Commands

  use CqrsMemorySyncWeb, :controller

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
    :ok = Commands.ship_product_quantity(sku, quantity)
    resp(conn, 200, "")
  end

  def ship_quantity(%Plug.Conn{} = conn, %{} = _params) do
    resp(conn, 400, "")
  end
end
