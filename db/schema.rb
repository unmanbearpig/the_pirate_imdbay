# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140427090441) do

  create_table "movies", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.string   "searchable_title"
    t.integer  "year"
    t.string   "director"
    t.string   "poster_url"
  end

  add_index "movies", ["searchable_title"], name: "index_movies_on_searchable_title"
  add_index "movies", ["title"], name: "index_movies_on_title"
  add_index "movies", ["year"], name: "index_movies_on_year"

  create_table "torrents", force: true do |t|
    t.string   "title"
    t.integer  "seeders"
    t.integer  "leechers"
    t.string   "magnet_link"
    t.string   "url"
    t.integer  "movie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size"
  end

  add_index "torrents", ["movie_id"], name: "index_torrents_on_movie_id"
  add_index "torrents", ["title"], name: "index_torrents_on_title"

end
