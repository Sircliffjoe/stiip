class AddBodyAndExcerptToEducationalContents < ActiveRecord::Migration[8.0]
  def change
    add_column :educational_contents, :body, :text
    add_column :educational_contents, :excerpt, :text
  end
end
