defmodule CqrsExample.Warehouse.Commands.State do
  @moduledoc false

  alias CqrsExample.Repo
  alias CqrsExample.Warehouse.Commands.InsufficientQuantityOnHandError
  alias CqrsExample.Warehouse.Commands.State.Product

  require Ecto.Query

  @spec adjust_product_quantity(String.t(), integer()) ::
          :ok | {:error, InsufficientQuantityOnHandError.t()}
  def adjust_product_quantity(sku, quantity) do
    Ecto.Query.from(p in Product,
      where: p.sku == ^sku,
      update: [set: [quantity: p.quantity + ^quantity]]
    )
    |> Repo.update_all([])
    |> case do
      {1, nil} -> :ok
      {0, nil} -> insert_new_product(sku, quantity)
    end
  rescue
    e in Postgrex.Error ->
      case e do
        %Postgrex.Error{postgres: %{constraint: "not_negative_quantity"}} ->
          {:error, %InsufficientQuantityOnHandError{}}
      end
  end

  @spec insert_new_product(String.t(), integer()) ::
          :ok | {:error, InsufficientQuantityOnHandError.t()}
  defp insert_new_product(sku, quantity) do
    {:ok, _record} =
      %Product{
        sku: sku,
        quantity: quantity
      }
      |> Repo.insert()

    :ok
  rescue
    e in Ecto.ConstraintError ->
      case e do
        %Ecto.ConstraintError{constraint: "not_negative_quantity"} ->
          {:error, %InsufficientQuantityOnHandError{}}
      end
  end
end
