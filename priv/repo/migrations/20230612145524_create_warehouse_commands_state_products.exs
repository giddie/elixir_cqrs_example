defmodule CqrsExample.Repo.Migrations.CreateWarehouseCommandsStateProducts do
  use Ecto.Migration

  def change do
    prefix = "warehouse_commands_state"

    execute(
      """
      CREATE SCHEMA #{prefix}
      """,
      """
      DROP SCHEMA #{prefix}
      """
    )

    create table("products", prefix: prefix, primary_key: false) do
      add :sku, :text, primary_key: true
      add :quantity, :integer, null: false
    end

    create unique_index("products", :sku, prefix: prefix)
    create constraint("products", :not_negative_quantity, prefix: prefix, check: "quantity >= 0")
  end
end
