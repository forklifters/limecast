module ReviewsHelper
  def can_add_reviews?(podcast)
    current_user.nil? || !podcast.been_reviewed_by?(current_user)
  end

  def review_rating(review, with_label = false)
    if review.positive
      img = image_tag('icons/thumbs_up.png', :alt => 'Thumbs Up', :class => 'rating')
      with_label ? img + "Positive" : img
    else
      img = image_tag('icons/thumbs_down.png', :alt => 'Thumbs Down', :class => 'rating')
      with_label ? img + "Negative" : img
    end
  end

  def review_by_line(review)
    "Written by #{link_to_profile review.reviewer} #{time_ago_in_words review.created_at} ago"
  end
end
