require 'the_pirate_bay_fetcher'

class Torrent < ActiveRecord::Base
  belongs_to :movie

  def url
    "https://thepiratebay.se/torrent/#{id}/"
  end

  def clean_title
    @clean_title ||= ThePirateBayFetcher.clean_title title
  end

  def searchable_title
    @searchable_title ||= ThePirateBayFetcher.searchable_title title
  end

  def year
    @year ||= ThePirateBayFetcher.extract_year title
  end

  def self.search query, options = {}
    torrents = fetch_query query
    torrents_with_movies = Movie.assign_movies_to_torrents torrents
    group_by_movies torrents_with_movies, options
  end

  def self.top category = ThePirateBay::Category::All, options = {}
    torrents = fetch_top category
    torrents_with_movies = Movie.assign_movies_to_torrents torrents
    group_by_movies torrents_with_movies, options
  end

  def self.fetch_query query
    puts "HTTP tpb search \"#{query}\""
    ThePirateBayFetcher.search(query).map { |t| import t }
  end

  def self.fetch_top category = ThePirateBay::Category::All
    puts "HTTP tpb top #{category}"
    ThePirateBayFetcher.top(category).map { |t| import t }
  end

  def self.group_by_movies torrents, options = {}
    grouped = torrents.reduce({}) do |movies, torrent|
      movies[torrent.movie_id] = { movie: torrent.movie, torrents: [] } unless movies.key? torrent.movie_id
      movies[torrent.movie_id][:torrents].push torrent
      movies
    end.map { |k, v| v }

    if options[:full_info]
      grouped.map { |tm| tm[:movie] }.each(&:fetch_info)
    end

    grouped
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
    self.size = tpb_torrent.size

    save!
    self
  end

  private


end
