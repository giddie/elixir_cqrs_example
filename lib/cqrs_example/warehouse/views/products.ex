defmodule CqrsExample.Warehouse.Views.Products do
  @moduledoc """
  Offers a view of products in the warehouse. Each product has a SKU and a quantity.
  """

  alias CqrsExample.Repo
  alias __MODULE__.DbRecord

  require Ecto.Query

  defmodule Product do
    @moduledoc """
    A product in the warehouse.
    """

    alias __MODULE__, as: Self

    @enforce_keys [:sku, :quantity]
    defstruct @enforce_keys

    @type t :: %Self{
            sku: String.t(),
            quantity: non_neg_integer()
          }
  end

  @doc """
  Lists all the products in the warehouse.
  """
  @spec list() :: [Product.t()]
  def list() do
    Repo.all(DbRecord)
    |> Enum.map(fn %DbRecord{} = record ->
      %Product{
        sku: record.sku,
        quantity: record.quantity
      }
    end)
  end

  @doc """
  Returns the quantity of a given product in the warehouse.
  """
  @spec get_quantity(String.t()) :: non_neg_integer()
  def get_quantity(sku) when is_binary(sku) do
    Ecto.Query.from(p in DbRecord, where: p.sku == ^sku)
    |> Repo.one()
    |> case do
      nil -> 0
      %DbRecord{} = record -> record.quantity
    end
  end

  @doc """
  Adjusts the quantity of a given product in the warehouse in the view's internal state. Should
  not generally be used directly.
  """
  @spec adjust_quantity(String.t(), integer()) :: :ok
  def adjust_quantity(sku, quantity) do
    Ecto.Query.from(p in DbRecord,
      where: p.sku == ^sku,
      update: [set: [quantity: p.quantity + ^quantity]]
    )
    |> Repo.update_all([])
    |> case do
      {1, nil} -> :ok
      {0, nil} -> insert_new(sku, quantity)
    end
  end

  @spec insert_new(String.t(), integer()) :: :ok
  defp insert_new(sku, quantity) do
    {:ok, _record} =
      %DbRecord{
        sku: sku,
        quantity: quantity
      }
      |> Repo.insert()

    :ok
  end
end
