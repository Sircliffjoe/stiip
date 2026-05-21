class CreateSectors < ActiveRecord::Migration[8.0]
  def change
    create_table :sectors, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :icon

      t.timestamps
    end
    add_index :sectors, :slug, unique: true
    add_index :sectors, :name, unique: true
  end
end
