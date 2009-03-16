# == Schema Information
# Schema version: 20090306193031
#
# Table name: taggings
#
#  id         :integer(4)    not null, primary key
#  tag_id     :integer(4)
#  podcast_id :integer(4)
#

class Tagging < ActiveRecord::Base
  belongs_to :podcast
  belongs_to :tag, :counter_cache => true

  has_many :user_taggings, :dependent => :destroy
  has_many :users, :through => :user_taggings

  before_save :map_to_different_tag

  named_scope :sorted_by_podcast, :order => "REPLACE(podcasts.title, 'The ', '')", :include => :podcast
  named_scope :for_podcast, lambda { |podcast| {:conditions => {:podcast_id => podcast}} }

  attr_accessor :user, :user_id

  validates_uniqueness_of :tag_id, :scope => :podcast_id, :message => "has already been used on this Podcast"

  def map_to_different_tag
    return if self.tag.nil?

    self.tag = self.tag.map_to until self.tag.map_to.nil?
  end
end
