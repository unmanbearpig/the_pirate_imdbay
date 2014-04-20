class MovieInfoFetcher
  def self.clean_title torrent
    torrent[:title]
      .gsub(/[\.\-_]/, ' ')
      .gsub(/[\[\]\(\)_\-\.]/, '')
      .gsub(/\s+/, ' ')
      .gsub(/([xh]264|2hd|eztv|hdtv|xvid|divx|mkv|720p?|1080[ip]?|dvdscr).*/i, '')
      .gsub(/\w{2,3}rip.*/i, '')
      .gsub(/\s(19|20)\d{2}.*/i, '')
      .gsub(/\ss\d\de\d\d.*/i, '')
      .strip
  end

  def self.extract_year torrent
    match = torrent[:title].match(/[\[\(\s]((?:19|20)\d\d)[\]\)\s$]/)
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
    hash[:clean_title] = clean_title torrent
    hash[:year] = ( extract_year(torrent) || nil )
    hash.merge!(extract_episode(torrent) || {})
    hash
  end

  def self.format_torrents torrents
    torrents.map { |torrent| extract_metadata(torrent) }
  end

  def self.top category = ThePirateBay::Category::All
    format_torrents(ThePirateBay::Top.new(category).torrents)
  end

  def self.search query
    format_torrents(ThePirateBay::Search.new(query).torrents)
  end

end
