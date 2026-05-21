class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :action, null: false
      t.references :auditable, polymorphic: true, type: :uuid
      t.jsonb :metadata, default: {}
      t.string :ip_address

      t.timestamps
    end
  end
end
