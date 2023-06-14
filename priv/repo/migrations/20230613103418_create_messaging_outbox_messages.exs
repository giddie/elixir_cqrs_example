defmodule CqrsExample.Repo.Migrations.CreateMessagingOutboxMessages do
  use Ecto.Migration

  def change do
    prefix = "messaging"

    execute(
      """
      CREATE SCHEMA #{prefix}
      """,
      """
      DROP SCHEMA #{prefix}
      """
    )

    create table("outbox_messages", prefix: prefix) do
      add :type, :text, null: false
      add :schema_version, :integer, null: false
      add :payload, :bytea, null: false
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    execute(
      """
      CREATE FUNCTION #{prefix}.notify_outbox_messages() RETURNS trigger AS
      $$
        BEGIN
          NOTIFY messaging__outbox_messages;
          RETURN NULL;
        END
      $$
      LANGUAGE plpgsql
      """,
      """
      DROP FUNCTION #{prefix}.notify_outbox_messages()
      """
    )

    execute(
      """
      CREATE TRIGGER insert_notify AFTER INSERT ON #{prefix}.outbox_messages
      EXECUTE FUNCTION #{prefix}.notify_outbox_messages()
      """,
      """
      DROP TRIGGER insert_notify ON #{prefix}.outbox_messages
      """
    )
  end
end
