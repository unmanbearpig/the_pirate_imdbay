class AddMovieInfo < ActiveRecord::Migration
  def change
    add_column :movies, :title, :string
    add_index :movies, :title

    add_column :movies, :searchable_title, :string
    add_index :movies, :searchable_title

    add_column :movies, :year, :integer
    add_index :movies, :year

    add_column :movies, :director, :string
    add_column :movies, :poster_url, :string
  end
end
