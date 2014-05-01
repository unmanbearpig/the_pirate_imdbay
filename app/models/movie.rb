require 'the_pirate_bay_fetcher'

class Movie < ActiveRecord::Base
  has_many :movie_titles
  has_many :torrents

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
    self.year = imdb.year
    self.director = imdb.director.first
    self.poster_url = imdb.poster

    save
  end

  def self.import imdb_movie
    return nil unless imdb_movie

    movie = find_or_initialize_by id: imdb_movie.id

    movie.title = imdb_movie.title
    movie.searchable_title = ThePirateBayFetcher.searchable_title imdb_movie.title
    movie.year = imdb_movie.year
    movie.poster_url = imdb_movie.poster

    movie.save! ? movie : nil
  end

  def self.search_online query
    puts "HTTP Imdb search for \"#{query}\""
    movies = Imdb::Search.new(query).movies

    movies.map { |movie| self.import movie }.reject(&:nil?)
  end

  def self.find_by_torrent torrent
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
    movie = find_by_torrent(torrent)
    return movie if movie

    self.search_online(torrent.clean_title + (torrent.year ? " #{torrent.year}" : ''))
      .first
  end

  def self.match_movies_to_torrents movies, torrents
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
    torrents = assign_known_movies_to_torrents(torrents)
    torrents_without_movies = torrents.reject(&:movie)

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

    torrents
  end

  def self.assign_known_movies_to_torrents torrents
    torrents.reject(&:movie).each do |torrent|
      movie = find_by_torrent torrent
      torrent.movie = movie if movie
      torrent.save
      torrent
    end
    torrents
  end

  def self.batch_search_movies_by_torrents torrents
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
