class CreateWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlist_items, id: :uuid do |t|
      t.references :watchlist, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :watchlist_items, [:watchlist_id, :company_id], unique: true
  end
end
