require 'the_pirate_bay_fetcher'

class Movie < ActiveRecord::Base
  has_many :movie_titles
  has_many :torrents

  scope :has_full_info, -> { where 'year != null or director != null or rating != null or votes != null' }
  scope :no_full_info, -> { where 'year == null and director == null and rating == null and votes == null' }


  def thumbnail_url
    if respond_to?(:poster_url) && poster_url
      poster_url.gsub(/(.jpg)/, "._V1_SY200_CR1,0,136,200_AL_.jpg")
    else
      nil
    end
  end

  def imdb_url
    "http://www.imdb.com/title/tt#{id}/"
  end

  def imdb
    @imdb ||= Imdb::Movie.new id
  end

  def fetch_info
    Rails.logger.info "Movie#fetch_info"

    return true if has_full_data?

    self.year = imdb.year
    self.director = imdb.director.first
    self.rating = imdb.rating
    self.votes = imdb.votes

    save
  end

  def has_full_data?
    Rails.logger.info "Movie#has_full_data?"

    self.year && self.director && self.rating && self.votes
  end

  def self.import imdb_movie
    return nil unless imdb_movie

    Rails.logger.info "Movie.import"

    movie = find_or_initialize_by id: imdb_movie.id

    movie.title = imdb_movie.title
    movie.searchable_title = ThePirateBayFetcher.searchable_title imdb_movie.title
    movie.year = imdb_movie.year
    movie.poster_url = imdb_movie.poster

    movie.save! ? movie : nil
  end

  def self.import_movies imdb_movies
    Rails.logger.info "Movie.import_movies"

    imdb_movies_hash = imdb_movies.reduce({}) { |hash, movie| hash[movie.id] = movie; hash }
    found_movies = Movie.where(id: imdb_movies_hash.keys)
    found_ids = Set.new(found_movies.map(&:id))
    not_found_ids = Set.new(imdb_movies_hash.keys) - found_ids

    found_movies.all + not_found_ids.map {|id| Movie.import(imdb_movies_hash[id]) }
  end

  def self.search_online query
    Rails.logger.info "Movie.search_online \"#{query}\""

    movies = Imdb::Search.new(query).movies

    import_movies movies
  end

  def self.find_by_torrent torrent
    Rails.logger.info "Movie.find_by_torrent"

    if torrent.year
      return where(searchable_title: torrent.searchable_title, year: torrent.year).first
    else
      movie = where(title: torrent.clean_title).first
      return movie if movie

      movie = where(title: torrent.title).first
      return movie if movie

      movie = where(searchable_title: torrent.searchable_title).first
      return movie if movie

    end
    return nil
  end

  def self.search_for_torrent torrent
    Rails.logger.info "Movie.search_for_torrent"

    movie = find_by_torrent(torrent)
    return movie if movie

    self.search_online(torrent.clean_title + (torrent.year ? " #{torrent.year}" : ''))
      .first
  end

  def self.match_movies_to_torrents movies, torrents
    Rails.logger.info "Movie.match_movies_to_torrents"

    movies_hash = movies.reduce({}) { |a, movie| a["#{movie.searchable_title} #{movie.year}"]; a }
    torrents.map do |torrent|
      unless torrent.movie
        if movie = movies_hash["#{torrent.searchable_title} #{torrent.year}"]
          torrent.movie = movie
          torrent.save
        end
      end
      torrent
    end
  end

  def self.assign_movies_to_torrents torrents
    Rails.logger.info "Movie.assign_movies_to_torrents"

    torrents = assign_known_movies_to_torrents(torrents)
    Rails.logger.info "Found known movies"

    torrents_without_movies = Torrent.where(id: torrents.map(&:id), movie: nil)

    return torrents if torrents_without_movies.empty?

    Rails.logger.info "Could not find #{torrents_without_movies.length} movies for torrents in db"

    movies = batch_search_movies_by_torrents torrents_without_movies
    match_movies_to_torrents movies, torrents
    torrents_without_movies = torrents.reject(&:movie)

    torrents_without_movies.each do |torrent|
      movie = search_for_torrent torrent
      if movie
        torrent.movie = movie
        torrent.save
      end
    end

    Rails.logger.info "All movies found"
    torrents
  end

  def self.assign_known_movies_to_torrents torrents
    Rails.logger.info "Movie.assign_known_movies_to_torrents"

    torrent_ids = torrents.map(&:id)
    movieless_torrents = Torrent.where(id: torrent_ids, movie: nil)

    movieless_torrents.each do |torrent|
      movie = find_by_torrent torrent
      torrent.movie = movie if movie
      torrent.save
      torrent
    end

    torrents
  end

  def self.batch_search_movies_by_torrents torrents
    Rails.logger.info "Movie.batch_search_movies_by_torrents"

    torrents.in_groups_of(10).reduce([]) do |movies, torrents|
      search_query = torrents.reject(&:nil?).map(&:clean_title).join(' ')
      movies + search_online(search_query)
    end
  end

  def self.profile_online_search query
    result = RubyProf.profile do
      search_online query
    end

    printer = RubyProf::GraphHtmlPrinter.new(result)

    File.open('profile.html', 'w') do |file|
      printer.print(file)
    end
  end
end
