class CreateTorrents < ActiveRecord::Migration
  def change
    create_table :torrents do |t|
      t.string :title
      t.integer :seeders
      t.integer :leechers
      t.string :magnet_link
      t.string :url
      t.references :movie, index: true

      t.timestamps
    end
  end
end
