require 'the_pirate_bay_fetcher'

class Torrent < ActiveRecord::Base
  belongs_to :movie

  TORRENT_DATA_EXPIRATION_TIME = 1.day

  scope :up_to_date, -> { where 'updated_at > ?', DateTime.now - TORRENT_DATA_EXPIRATION_TIME }

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
    Rails.logger.info "Torrent.search \"#{query}\""

    torrents = fetch_query query
    torrents_with_movies = Movie.assign_movies_to_torrents torrents
    group_by_movies torrents_with_movies, options
  end

  def self.top category = ThePirateBay::Category::All, options = {}
    Rails.logger.info "Torrent.top #{category}"

    torrents = fetch_top category
    torrents_with_movies = Movie.assign_movies_to_torrents torrents
    group_by_movies torrents_with_movies, options
  end

  def self.fetch_query query
    Rails.logger.info "Torrent.fetch_query \"#{query}\""

    import_torrents ThePirateBayFetcher.search(query)
  end

  def self.fetch_top category = ThePirateBay::Category::All
    Rails.logger.info "Torrent.fetch_top #{category}"

    import_torrents ThePirateBayFetcher.top(category)
  end

  def self.group_by_movies torrents, options = {}
    Rails.logger.info "Torrent.group_by_movies"
    grouped = torrents.reduce({}) do |movies, torrent|
      movies[torrent.movie_id] = { movie: torrent.movie, torrents: [] } unless movies.key? torrent.movie_id
      movies[torrent.movie_id][:torrents].push torrent
      movies
    end.map { |k, v| v }

    if options[:full_info]
      ids = grouped.select { |tm| tm[:movie] }.map { |tm| tm[:movie].id }
      Movie.where(id: ids).no_full_info.each { |movie| movie.fetch_info }
    end

    grouped
  end

  def self.import tpb_torrent
    Rails.logger.info "Torrent.import"

    torrent = Torrent.where(id: tpb_torrent.id).first
    return torrent if torrent && torrent.up_to_date?

    torrent = Torrent.new(id: tpb_torrent.id) unless torrent
    torrent.update_data tpb_torrent
    torrent.save! ? torrent : nil
  end

  def self.import_torrents tpb_torrents
    ids = Set.new(tpb_torrents.map(&:id))
    up_to_date_torrents = Torrent.where(id: ids.to_a).up_to_date.includes(:movie)
    up_to_date_ids = Set.new(up_to_date_torrents.map(&:id))

    not_up_to_date_ids = ids - up_to_date_ids

    tpb_torrents_hash = tpb_torrents.reduce({}) { |hash, torrent| hash[torrent.id] = torrent; hash }

    not_up_to_date_torrents = not_up_to_date_ids.map { |id| tpb_torrents_hash[id] }
    return up_to_date_torrents + not_up_to_date_torrents.map { |torrent| Torrent.import torrent }
  end

  def update_data tpb_torrent
    Rails.logger.info "Torrent#update_data"

    return self if up_to_date?

    self.title = tpb_torrent.title
    self.seeders = tpb_torrent.seeders
    self.leechers = tpb_torrent.leechers
    self.magnet_link = tpb_torrent.magnet_link
    self.size = tpb_torrent.size

    save!
    self
  end

  def up_to_date?
    return nil unless updated_at
    updated_at > (DateTime.now - TORRENT_DATA_EXPIRATION_TIME)
  end

  private


end
