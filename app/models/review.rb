# == Schema Information
# Schema version: 20100504173954
#
# Table name: reviews
#
#  id             :integer(4)    not null, primary key
#  user_id        :integer(4)    
#  body           :text(16777215 
#  created_at     :datetime      
#  updated_at     :datetime      
#  title          :string(255)   
#  positive       :boolean(1)    
#  insightful     :integer(4)    default(0)
#  not_insightful :integer(4)    default(0)
#  podcast_id     :integer(4)    
#

class Review < ActiveRecord::Base
  belongs_to :podcast
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'user_id'

  has_many :review_ratings, :dependent => :destroy

  after_create  { |c| c.reviewer.calculate_score! if c.reviewer }
  after_destroy { |c| c.reviewer.calculate_score! if c.reviewer }

  validates_presence_of :podcast_id, :body
  validates_uniqueness_of :user_id, :scope => :podcast_id

  named_scope :older_than, lambda {|date| {:conditions => ["reviews.created_at < (?)", date]} }
  named_scope :newer_than, lambda {|who| {:conditions => ["reviews.created_at >= (?)", who.created_at]} }
  named_scope :without, lambda {|who| {:conditions => ["reviews.id NOT IN (?)", who.id]} }
  named_scope :that_are_positive, :conditions => {:positive => true}
  named_scope :that_are_negative, :conditions => {:positive => false}
  named_scope :newest, lambda {|*count| {:limit => (count[0] || 1), :order => "created_at DESC"} }
  named_scope :unclaimed, :conditions => "user_id IS NULL"
  named_scope :claimed, :conditions => "user_id IS NOT NULL"
  named_scope :by_admin, :conditions => "users.admin = 1", :include => :reviewer
  named_scope :by_nonadmin, :conditions => "users.admin IS NULL OR users.admin = 0", :include => :reviewer

  define_index do
    indexes :title, :body

    has podcast(:id), :as => :podcast_id
    has :created_at
  end

  def writable_by?(user)
    return false unless user
    return true if user.admin?

    user == self.reviewer
  end

  def rated_by?(user)
    user && self.review_ratings.exists?(:user_id => user.id)
  end

  def claim_by(user)
    update_attribute(:reviewer, user)
  end

  def insightful
    self.review_ratings.claimed.insightful.count
  end

  def not_insightful
    self.review_ratings.claimed.not_insightful.count
  end
end
