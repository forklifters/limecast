class EpisodesController < ApplicationController
  before_filter :login_required, :only => [:favorite]

  def index
    @podcast  = Podcast.find_by_slug(params[:podcast_slug])

    @episodes = @podcast.episodes.find(:all, :include => [:podcast], :order => "published_at DESC")
    @newest_episode = @episodes.first
    @oldest_episode = @episodes.last if @episodes.size > 1
    @feeds    = @podcast.feeds
  end

  def search
    @q        = params[:q]
    @podcast  = Podcast.find_by_slug(params[:podcast_slug])
    @episodes = @podcast.episodes.search(@q, :include => [:podcast]).compact.uniq.sort_by(&:published_at)
    @feeds    = @podcast.feeds
    render :action => 'index'
  end

  def show
    @podcast = Podcast.find_by_slug(params[:podcast_slug])


    @episode = @podcast.episodes.find_by_slug(params[:episode])
    raise ActiveRecord::RecordNotFound if @episode.nil? || params[:episode].nil?

    @feeds   = @podcast.feeds
    @review = Review.new(:episode => @episode)
  end

  def destroy
    @episode = Episode.find(params[:id])
    unauthorized unless @episode.writable_by?(current_user)

    @episode.destroy
  end
end
