class CreateDataImportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :data_import_logs, id: :uuid do |t|
      t.string :data_type, null: false, index: true
      t.string :provider, null: false, index: true
      t.string :status, default: "pending", null: false, index: true
      t.integer :records_imported, default: 0
      t.text :error_message
      t.uuid :user_id, index: true
      t.timestamps
    end

    add_foreign_key :data_import_logs, :users, column: :user_id, on_delete: :nullify
    
    # Compound index for common queries
    add_index :data_import_logs, [:data_type, :created_at], name: "idx_data_imports_type_date"
    add_index :data_import_logs, [:status, :created_at], name: "idx_data_imports_status_date"
  end
end
