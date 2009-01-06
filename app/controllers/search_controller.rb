class SearchController < ApplicationController
  def index
    q = (@q = params[:q]).dup
    
    # match Podcast, ex: "podcast:Diggnation"
    q.gsub!(/(\b)*podcast\:(\S*)/i, "")
    @podcast = Podcast.find_by_clean_url($2) unless $2.blank?
    raise ActiveRecord::RecordNotFound if @podcast && @podcast.nil?

    @users    = User.search(q).compact
    @tags     = Tag.search(q).compact
    @feeds    = (@podcast ? @podcast.feeds : Feed).search(q)
    @episodes = (@podcast ? @podcast.episodes : Episode).search(q)
    @reviews  = (@podcast ? Review.for_podcast(@podcast) : Review).search(q)
    @podcasts = @podcast ? [@podcast] : Podcast.search(q)

    @podcast_groups = Hash.new { |h, k| h[k] = [] } # hash where the keys are the unique podcast ids, 
                                                    # and the values are arrays of their search results
    def @podcast_groups.add(obj, podcast_id); self[podcast_id] << obj; end
    def @podcast_groups.count(klass); self.inject(0) { |count, p| count + p[1].map { |o| o.is_a?(klass) }.size }; end

    # Group all the podcast-related search results by podcast-id
    @feeds.compact.each    { |f| @podcast_groups.add(f, f.podcast.id) }
    @episodes.compact.each { |e| @podcast_groups.add(e, e.podcast.id) }
    @reviews.compact.each  { |r| @podcast_groups.add(r, r.episode.podcast.id) }

    # rewrites @podcasts to have all the podcasts we need
    @podcasts = Podcast.all(:conditions => {:id => @podcast_groups.keys}).compact #.sorted
  end
end
