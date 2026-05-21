class CreateCompanyNews < ActiveRecord::Migration[8.0]
  def change
    create_table :company_news, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :news_article, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :company_news, [:company_id, :news_article_id], unique: true
  end
end
