require 'the_pirate_bay_fetcher'

class Torrent < ActiveRecord::Base
  belongs_to :movie

  def self.search query
    search_results = ThePirateBayFetcher.search query
    search_results.map { |torrent| import torrent }
  end

  def self.top category = ThePirateBay::Category::All
    results = ThePirateBayFetcher.top category
    results.map { |torrent| import torrent }
  end

  def self.top_movies
    top ThePirateBay::Category::Video_Movies
  end

  def self.import tpb_torrent
    torrent = find_or_initialize_by id: tpb_torrent.torrent_id
    torrent.title = tpb_torrent.title
    torrent.seeders = tpb_torrent.seeders
    torrent.leechers = tpb_torrent.leechers
    torrent.magnet_link = tpb_torrent.magnet_link

    matching_movies = Movie.search_by_torrent tpb_torrent

    unless matching_movies.empty?
      first_movie = matching_movies.first
      torrent.movie = first_movie
    end

    torrent.save! ? torrent : nil
  end

  private

  def find_movie
    Movie.search
  end

end
