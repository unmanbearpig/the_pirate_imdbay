class AddIndexesToTorrent < ActiveRecord::Migration
  def change
    add_index :torrents, :title
  end
end
