class CreateDataSources < ActiveRecord::Migration[8.0]
  def change
    create_table :data_sources, id: :uuid do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.jsonb :config, default: {}
      t.boolean :active, default: true
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
