defmodule CqrsExample.Repo.Migrations.MoveViewsToSeparateSchema do
  use Ecto.Migration

  def up do
    execute """
      CREATE SCHEMA warehouse_views
    """

    execute """
      ALTER TABLE public.warehouse__products
      SET SCHEMA warehouse_views
    """

    execute """
      ALTER TABLE warehouse_views.warehouse__products
      RENAME TO products
    """
  end

  def down do
    execute """
      ALTER TABLE warehouse_views.products
      RENAME TO warehouse__products
    """

    execute """
      ALTER TABLE warehouse_views.warehouse__products
      SET SCHEMA public
    """

    execute """
      DROP SCHEMA warehouse_views
    """
  end
end
