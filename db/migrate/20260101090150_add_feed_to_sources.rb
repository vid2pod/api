class AddFeedToSources < ActiveRecord::Migration[8.0]
  def change
    add_reference :sources, :feed, null: false, foreign_key: true, type: :uuid
  end
end
