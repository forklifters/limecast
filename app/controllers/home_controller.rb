class HomeController < ApplicationController
  def home
    @podcasts = Podcast.parsed.sorted

    @reviews = Review.claimed.all(:order => "created_at DESC")
    @review = @reviews.first

    @recent_reviews = Review.claimed.newest(2).with_episode
    @recent_episodes = Episode.newest(3)
    @popular_tags = Tag.all #(:order => "taggings_count DESC")
  end
end
