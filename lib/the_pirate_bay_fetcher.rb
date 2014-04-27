class ThePirateBayTorrent
  attr_reader :torrent_hash

  def initialize torrent_hash
    @torrent_hash = torrent_hash

    torrent_hash.keys.each do |torrent_field|
      define_singleton_method torrent_field do
        torrent_hash[torrent_field]
      end
    end
  end

  def id
    torrent_id.to_i
  end

  def respond_to? *args
    torrent_hash.respond_to? *args
  end

  def method_missing method, *args
    if torrent_hash.respond_to? method
      torrent_hash.send method, *args
    end
  end

  def series?
    season && episode
  end

  def to_h
    torrent_hash
  end
end

class ThePirateBayFetcher
  def self.clean_title title
    title
      .gsub(/[\.\-_:;]/, ' ')
      .gsub(/[\[\]\(\)_\-\.]/, '')
      .gsub(/\s+/, ' ')
      .gsub(/([xh]264|2hd|eztv|hdtv|xvid|divx|mkv|720p?|1080[ip]?|dvdscr).*/i, '')
      .gsub(/\w{2,3}rip.*/i, '')
      .gsub(/[\s\w](19|20)\d{2}.*/i, '')
      .gsub(/\ss\d\de\d\d.*/i, '')
      .strip
  end

  def self.searchable_title title
    clean_title(title).downcase
  end

  def self.extract_year title
    match = title.match(/[\[\(\s]((?:19|20)\d\d)[\]\)\s$]/)
    match ? match[1].to_i : nil
  end

  def self.extract_episode torrent
    match = torrent[:title].match(/[\[\(\s]s(\d{1,3})e(\d{1,3})[\]\)\s$]/i)

    if match
      {season: match[1].to_i, episode: match[2].to_i}
    else
      nil
    end
  end

  def self.extract_metadata torrent
    hash = torrent.clone
    hash[:clean_title] = clean_title torrent[:title]
    hash[:year] = ( extract_year(torrent[:title]) || nil )
    hash[:searchable_title] = clean_title(torrent[:title]).downcase
    hash.merge!(extract_episode(torrent) || {})
    hash
  end

  def self.format_torrents torrents
    torrents.map do |torrent|
      ThePirateBayTorrent.new(extract_metadata(torrent))
    end
  end

  def self.top category = ThePirateBay::Category::All
    format_torrents(ThePirateBay::Top.new(category).torrents)
  end

  def self.search query
    format_torrents(ThePirateBay::Search.new(query).torrents)
  end

end
