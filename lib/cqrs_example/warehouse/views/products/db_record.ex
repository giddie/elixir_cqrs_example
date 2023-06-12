defmodule CqrsExample.Warehouse.Views.Products.DbRecord do
  @moduledoc false

  alias __MODULE__, as: Self

  use Ecto.Schema

  @schema_prefix "warehouse_views"
  @primary_key false
  schema "products" do
    field(:sku, :string, primary_key: true)
    field(:quantity, :integer)
    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %Self{
          sku: String.t(),
          quantity: non_neg_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }
end
