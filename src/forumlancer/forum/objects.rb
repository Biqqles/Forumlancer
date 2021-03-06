# frozen_string_literal: true

# This file defines objects for various "things" on the forum.

THREAD_ARCHIVE = 'https://discoverygc.com/forums/archive/index.php?thread-%<id>s'
SUBFORUM_FULL = 'https://discoverygc.com/forums/forumdisplay.php?fid=%<id>s'

# Mixin for a forum object which at minimum has a URL and an ID.
module ForumObject
  # This object's ID.
  # @return [String]
  def id
    full_url.delete('^0-9')
  end

  # A Markdown link to this object.
  # @return [String]
  def markdown
    "[#{name}](#{full_url})"
  end
end

# A subforum.
Subforum = Struct.new(:archive_url, :name) do
  include ForumObject

  # Reimplemented
  # @return [String]
  def id
    archive_url.delete('^0-9')
  end

  # The URL for the full version of this subforum.
  # @return [String]
  def full_url
    format(SUBFORUM_FULL, id: id)
  end
end

# A forum user. `full_url` is a link to their profile.
ForumUser = Struct.new(:full_url, :name) do
  include ForumObject
end

# A thread on the forum.
ForumThread = Struct.new(:full_url, :short_title, :last_user, :last_active) do
  include ForumObject

  # Alternative constructor from a ".latestthreads_portal" div.
  # @param portal [Nokogiri::XML::Element] The ".latestthreads_portal" element.
  # @return [ForumThread] The new ForumThread struct.
  def self.from_portal(portal)
    thread = portal.at('strong').at('a') # retaining "action=lastpost" is intentional

    metadata = portal.at('span')
    user = metadata.at('a')

    # a different time format is used for posts that were made before the current day
    time = metadata.at('span')['title'].yield_self do |t|
        Time.strptime(t, '%m-%d-%Y, %I:%M %p')
      rescue ArgumentError
        Time.strptime(t, '%m-%d-%Y')
    end

    ForumThread.new(thread['href'], thread.text, ForumUser.new(user['href'], user.text), time)
  end

  # The archive URL for this thread. Used for quickly getting its title.
  # @return [String]
  def archive_url
    format(THREAD_ARCHIVE, id: id)
  end

  # The document for the archive of this thread. (memoized).
  # @return [Nokogiri::HTML::Document]
  def archive_doc
    @archive_doc ||= fetch_url(archive_url)
  end

  # This thread's full title.
  # @return [String]
  def name
    short_title unless short_title.end_with? '...'
    archive_doc.at_css('#fullversion').at('a').text
  end

  # The user who started this thread.
  # @return [ForumUser]
  def started_by
    user = archive_doc.at_css('.author').at('a')
    ForumUser.new(user['href'], user.text)
  end

  # The subforum this thread is in.
  # @return [Subforum]
  def subforum
    link = archive_doc.css('.navigation').search('a').last
    Subforum.new(link['href'], link.text)
  end
end
