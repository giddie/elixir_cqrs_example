defmodule CqrsExample.Warehouse.Commands.State do
  @moduledoc """
  This is the domain model used by commands in the Warehouse context to enforce domain logic. This
  model should be used directly _only_ by the `CqrsExample.Warehouse.Commands` module.
  """

  alias CqrsExample.Repo
  alias CqrsExample.Warehouse.Commands.InsufficientQuantityOnHandError
  alias CqrsExample.Warehouse.Commands.State.Product

  require Ecto.Query

  @doc """
  Adjusts the quantity of the given SKU in the warehouse. The quantity adjustment may be positive
  or negative.
  """
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

  @doc """
  Returns the current quantity of a given SKU in the warehouse.
  """
  @spec get_product_quantity(String.t()) :: integer()
  def get_product_quantity(sku) when is_binary(sku) do
    Ecto.Query.from(p in Product, where: p.sku == ^sku)
    |> Repo.all()
    |> case do
      [%Product{} = product] -> product.quantity
      [] -> 0
    end
  end
end
