class MoviesController < ApplicationController
  layout 'with_header'

  def top
    category = params[:category] || ThePirateBay::Category::Video_Movies
    @movie_torrents = Torrent.top(category.to_i).reject { |mt| mt[:movie].nil? }
    render 'top_movie_torrents'
  end
end
