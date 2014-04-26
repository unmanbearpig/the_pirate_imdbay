require 'the_pirate_bay_fetcher'

class Movie < ActiveRecord::Base
  has_many :movie_titles
  has_many :torrents

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
    puts "Searching Imdb for \"#{query}\""
    movies = Imdb::Search.new(query).movies

    if first_movie = import(movies.first)
      first_movie.fetch_info
    end

    movies.map { |movie| self.import movie }
  end

  def self.find_by_torrent torrent
    where(searchable_title: torrent.searchable_title, year: torrent.year)
  end

  def self.search_by_torrent torrent
    movies = find_by_torrent(torrent)
    return movies if movies && !movies.empty?

    self.search_online "#{torrent.clean_title} #{torrent.year}"
  end
end
