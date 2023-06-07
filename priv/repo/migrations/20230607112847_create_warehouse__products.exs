defmodule CqrsExample.Repo.Migrations.CreateWarehouseProducts do
  use Ecto.Migration

  def change do
    create table("warehouse__products", primary_key: false) do
      add :sku, :text, primary_key: true
      add :quantity, :integer, null: false
      timestamps()
    end
  end
end
