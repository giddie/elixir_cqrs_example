defmodule CqrsExample.Warehouse.Commands.State.Product do
  @moduledoc false

  alias __MODULE__, as: Self
  alias Ecto.Changeset

  use Ecto.Schema
  import Changeset

  @schema_prefix "warehouse_commands_state"
  @primary_key false
  schema "products" do
    field(:sku, :string, primary_key: true)
    field(:quantity, :integer)
  end

  @type t :: %Self{
          sku: String.t(),
          quantity: non_neg_integer()
        }

  def changeset(%Self{} = self, params) do
    change(self) |> changeset(params)
  end

  def changeset(%Changeset{} = changeset, params) do
    required = [
      :sku,
      :quantity
    ]

    changeset
    |> cast(params, required)
    |> validate_required(required)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
  end
end
