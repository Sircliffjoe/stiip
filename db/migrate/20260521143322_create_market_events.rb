class CreateMarketEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :market_events, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.integer :event_type, default: 0, null: false
      t.datetime :event_date, null: false
      t.references :company, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
