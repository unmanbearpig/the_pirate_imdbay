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
    torrent = find_or_initialize_by id: tpb_torrent.id
    torrent.update_data tpb_torrent
    torrent.save! ? torrent : nil
  end

  def update_data tpb_torrent
    self.title = tpb_torrent.title
    self.seeders = tpb_torrent.seeders
    self.leechers = tpb_torrent.leechers
    self.magnet_link = tpb_torrent.magnet_link

    unless self.movie
      new_movie = Movie.search_by_torrent tpb_torrent
      self.movie = new_movie if new_movie
    end

    save!
    self
  end

  private


end
