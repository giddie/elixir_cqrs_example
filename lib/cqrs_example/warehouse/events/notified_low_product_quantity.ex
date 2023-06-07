defmodule CqrsExample.Warehouse.Events.NotifiedLowProductQuantity do
  @moduledoc false

  alias __MODULE__, as: Self

  @enforce_keys [:sku]
  defstruct @enforce_keys

  @type t :: %Self{
          sku: String.t()
        }
end
