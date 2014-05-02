class AddMetadataToMovies < ActiveRecord::Migration
  def change
    add_column :movies, :rating, :float
    add_column :movies, :votes, :int
    add_column :movies, :plot, :string
  end
end
