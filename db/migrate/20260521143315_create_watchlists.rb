class CreateWatchlists < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlists, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.boolean :is_default, default: false

      t.timestamps
    end
  end
end
