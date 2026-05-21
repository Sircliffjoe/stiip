class CreateNewsArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :news_articles, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.string :source
      t.string :source_url
      t.datetime :published_at
      t.boolean :featured, default: false
      t.string :category
      t.references :author, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
    add_index :news_articles, :slug, unique: true
  end
end
