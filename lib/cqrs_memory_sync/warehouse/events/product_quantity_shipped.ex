defmodule CqrsMemorySync.Warehouse.Events.ProductQuantityShipped do
  @moduledoc false

  alias __MODULE__, as: Self

  @enforce_keys [:sku, :quantity]
  defstruct @enforce_keys

  @type t :: %Self{
          sku: String.t(),
          quantity: non_neg_integer()
        }
end
