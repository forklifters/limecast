# == Schema Information
# Schema version: 20100504173954
#
# Table name: sources
#
#  id                       :integer(4)    not null, primary key
#  url                      :string(255)
#  type                     :string(255)
#  episode_id               :integer(4)
#  format                   :string(255)
#  screenshot_file_name     :string(255)
#  screenshot_content_type  :string(255)
#  screenshot_file_size     :string(255)
#  preview_file_name        :string(255)
#  preview_content_type     :string(255)
#  preview_file_size        :string(255)
#  downloaded_at            :datetime
#  hashed_at                :datetime
#  curl_info                :text(16777215
#  ffmpeg_info              :text(16777215
#  height                   :integer(4)
#  width                    :integer(4)
#  file_name                :string(255)
#  torrent_file_name        :string(255)
#  torrent_content_type     :string(255)
#  torrent_file_size        :string(255)
#  random_clip_file_name    :string(255)
#  random_clip_content_type :string(255)
#  random_clip_file_size    :string(255)
#  ability                  :integer(4)    default(0)
#  framerate                :string(20)
#  size_from_xml            :integer(4)
#  size_from_disk           :integer(4)
#  sha1hash                 :string(40)
#  torrent_info             :text(16777215
#  duration_from_ffmpeg     :integer(4)
#  duration_from_feed       :integer(4)
#  extension_from_feed      :string(255)
#  extension_from_disk      :string(255)
#  content_type_from_http   :string(255)
#  content_type_from_disk   :string(255)
#  content_type_from_feed   :string(255)
#  published_at             :datetime
#  podcast_id               :integer(4)
#  bitrate_from_feed        :integer(4)
#  bitrate_from_ffmpeg      :integer(4)
#  created_at               :datetime
#

class Source < ActiveRecord::Base
  IPHONE_EXTENSIONS = %w(mp3 m4a mp4) # mp4 wav m4v mov)

  belongs_to :episode
  belongs_to :podcast

  named_scope :stale,    :conditions => ["sources.ability < ?", ABILITY]
  named_scope :sorted, lambda {|*col| {:order => "#{col[0] || 'episodes.published_at'} DESC", :include => :episode} }
  named_scope :with_preview, :conditions => "sources.preview_file_size IS NOT NULL and CAST (sources.preview_file_size AS INTEGER) > 1023"
  named_scope :with_screenshot, :conditions => "sources.screenshot_file_size IS NOT NULL and CAST (sources.screenshot_file_size AS INTEGER) > 0"
  named_scope :audio, :conditions => "sources.content_type_from_http LIKE 'audio%' OR sources.content_type_from_feed LIKE 'audio%'"
  named_scope :sorted_by_bitrate, :order => "bitrate_from_feed DESC, bitrate_from_ffmpeg DESC"
  named_scope :sorted_by_extension, :order => "extension_from_feed DESC, extension_from_disk DESC"
  named_scope :sorted_by_extension_and_bitrate, :order => "extension_from_feed DESC, extension_from_disk DESC, bitrate_from_feed DESC, bitrate_from_ffmpeg DESC"
  named_scope :for_iphone, :conditions => ["(extension_from_feed IN (?) OR extension_from_disk IN (?))", IPHONE_EXTENSIONS, IPHONE_EXTENSIONS]
  named_scope :audio, :conditions => "width IS NULL AND height IS NULL"

  has_attached_file :screenshot, :styles => { :square => ["95x95#", :jpg] },
                    :url  => "/:attachment/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/:attachment/:id/:style/:basename.:extension"
  has_attached_file :preview,
                    :url  => "/:attachment/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/:attachment/:id/:style/:basename.:extension"
  has_attached_file :random_clip, # not currently being generated
                    :url  => "/:attachment/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/:attachment/:id/:style/:basename.:extension"
  has_attached_file :torrent,
                    :url  => "/:attachment/:to_param.torrent",
                    :path => ":rails_root/public/:attachment/:to_param.torrent"


  def archived?
    episode.archived?
  end
  alias :archived :archived?

  # Only check if we set a :file_name from "update_sources"; the File.basename method
  # might not be reliable because some places use weird urls
  def file_name?
    !read_attribute('file_name').blank?
  end

  def file_name
    read_attribute('file_name') || File.basename(url.to_s)
  end

  def to_param
    podcast_name = episode.podcast.clean_url
    episode_date = episode.clean_url


    # NOTE from 2/4/10: taking out formatted_bitrate from source.to_param for now because
    #                   the source might not have a bitrate before it generates the torrent
    #                   (if it wasn't in the feed) and the filename would be missing that, so now we'll have:
    #
    #                   47905-Diggnation-2009-Sep-23--avi.torrent
    #
    #                     instead of the ideal:
    #
    #                   47905-Diggnation-2009-Sep-23-742kbps-avi.torrent
    #
    # "#{id}-#{podcast_name}-#{episode_date}-#{formatted_bitrate}-#{extension}"
    "#{id}-#{podcast_name}-#{episode_date}--#{extension}"
  end

  # Note: we'll use this as the defacto format instead of format() because
  # format() is derived from ffmpeg output, which has been wrong in some cases
  def extension
    extension_from_disk.blank? ? extension_from_feed : extension_from_disk
  end

  def magnet_url
   params = [
     ("xt=urn:sha1:#{sha1hash}" unless sha1hash.blank?),
     ("dn=#{file_name}" if file_name?),
     "xl=#{size}",
     "xs=#{url}"
   ].compact.join("&")

   "magnet:?#{params}"
  end

  def resolution
    @resolution ||= ([self.width, self.height].join("x") if self.width && self.height)
  end

  def size
    self.size_from_disk || self.size_from_xml || 0
  end

  def content_type
    self.content_type_from_feed || self.content_type_from_disk || ""
  end

  def duration
    if(duration_from_ffmpeg && duration_from_ffmpeg > 0)
      duration_from_ffmpeg
    else
      duration_from_feed || 0
    end
  end

  def formatted_bitrate
    bitrate.to_bitrate.to_s if bitrate and bitrate > 0
  end

  def formatted_framerate
    framerate.to_s.split(' ').first + "fps" unless framerate.blank?
  end

  def bitrate
    @bitrate ||= if(bitrate_from_ffmpeg && bitrate_from_ffmpeg > 0)
                   bitrate_from_ffmpeg
                 elsif(bitrate_from_feed && bitrate_from_feed > 0)
                   bitrate_from_feed
                 elsif(size > 0 && duration > 0)
                   (((size || 0) * 8) / 1000.0) / duration.to_f
                 else
                   0
                 end.to_i
  end

  # Returns "video" if video is available, "audio" if audio but not video is available, and nil if neither.
  def preview_type
    return "video" if %w(mp4 m4v mov flv avi asf).include?(format)
    return "audio" if !format.blank?
    return nil
  end

  def video?
    self.content_type =~ /^video/
  end

  def audio?
    self.width.blank? || self.content_type =~ /^audio/
  end
end
