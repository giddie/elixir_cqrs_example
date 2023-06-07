defmodule CqrsExample.Warehouse.Views.Products do
  @moduledoc false

  alias CqrsExample.Repo
  alias __MODULE__.DbRecord

  require Ecto.Query

  defmodule Product do
    @moduledoc false

    alias __MODULE__, as: Self

    @enforce_keys [:sku, :quantity]
    defstruct @enforce_keys

    @type t :: %Self{
            sku: String.t(),
            quantity: non_neg_integer()
          }
  end

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

  @spec get_quantity(String.t()) :: non_neg_integer()
  def get_quantity(sku) when is_binary(sku) do
    Ecto.Query.from(p in DbRecord, where: p.sku == ^sku)
    |> Repo.one()
    |> case do
      nil -> 0
      %DbRecord{} = record -> record.quantity
    end
  end

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
