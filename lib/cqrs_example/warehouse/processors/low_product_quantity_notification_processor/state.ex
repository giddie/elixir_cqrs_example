defmodule CqrsExample.Warehouse.Processors.LowProductQuantityNotificationProcessor.State do
  @moduledoc false

  alias __MODULE__, as: Self

  use Ecto.Schema

  @schema_prefix "warehouse_processors"
  @primary_key false
  schema "low_product_quantity_notification" do
    field(:sku, :string, primary_key: true)
    field(:quantity, :integer)
  end

  @type t :: %Self{
          sku: String.t(),
          quantity: non_neg_integer()
        }
end
