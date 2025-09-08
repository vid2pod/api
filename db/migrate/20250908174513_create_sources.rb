class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources, id: :uuid do |t|
      t.string :url
      t.string :source_type
      t.string :platform

      t.timestamps
    end
  end
end
