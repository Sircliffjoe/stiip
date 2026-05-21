class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings, id: :uuid do |t|
      t.references :tag, null: false, foreign_key: true, type: :uuid
      t.references :taggable, polymorphic: true, null: false, type: :uuid

      t.timestamps
    end
    add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true, name: 'index_taggings_uniqueness'
  end
end
