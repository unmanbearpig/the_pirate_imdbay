class MoviesController < ApplicationController
  layout 'with_header'

  def top_movie_torrents
    @movie_torrents = Torrent.top_movies
  end
end
