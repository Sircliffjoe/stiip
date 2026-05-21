class CreateEducationalContents < ActiveRecord::Migration[8.0]
  def change
    create_table :educational_contents, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.string :category
      t.integer :difficulty_level, default: 0
      t.boolean :featured, default: false
      t.references :author, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :published_at

      t.timestamps
    end
    add_index :educational_contents, :slug, unique: true
  end
end
