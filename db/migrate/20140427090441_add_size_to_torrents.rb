class AddSizeToTorrents < ActiveRecord::Migration
  def change
    add_column :torrents, :size, :integer
  end
end
