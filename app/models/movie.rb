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
    movie = find_or_initialize_by id: imdb_movie.id

    movie.title = ThePirateBayFetcher.clean_title imdb_movie.title
    movie.searchable_title = ThePirateBayFetcher.searchable_title imdb_movie.title
    movie.year = ThePirateBayFetcher.extract_year imdb_movie.title

    movie.save! ? movie : nil
  end

  def self.search_online query
    puts "HTTP Imdb search for \"#{query}\""
    movies = Imdb::Search.new(query).movies

    if first_movie = import(movies.first)
      first_movie.fetch_info
    end

    movies.map { |movie| self.import movie }
  end

  def self.find_by_torrent torrent
    where(searchable_title: torrent.searchable_title, year: torrent.year).first
  end

  def self.search_by_torrent torrent
    movie = find_by_torrent(torrent)
    return movie if movie

    self.search_online(torrent.clean_title + (torrent.year ? " #{torrent.year}" : ''))
      .first
  end
end
