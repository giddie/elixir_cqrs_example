defmodule CqrsExample.Repo.Migrations.CreateWarehouseLowProductQuantityNotificationProcessor do
  use Ecto.Migration

  def change do
    prefix = "warehouse_processors"

    execute(
      """
      CREATE SCHEMA #{prefix}
      """,
      """
      DROP SCHEMA #{prefix}
      """
    )

    create table("low_product_quantity_notification", prefix: prefix, primary_key: false) do
      add :sku, :text, primary_key: true
      add :quantity, :integer, null: false
    end

    create unique_index("low_product_quantity_notification", :sku, prefix: prefix)
  end
end
