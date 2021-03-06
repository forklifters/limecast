$(document).ready(function(){
  var enableReviewLinks = function() {
    // review rating links
    $('a.rate').click(function(){
      var link = $(this);
      var id = link.attr('rel');

      $.ajax({
        url: link.attr('href'),
        dataType: 'json',
        success: function(resp,ev) {
          if(resp.logged_in) window.location.reload();
        }
      });

      return false;
    });

    // review list toggles
    $(".reviews.list .linkable a").click(function(){
      $(".reviews.list .linkable.current").removeClass('current');
      $(this).parent('span.linkable').addClass('current');

      if ($(this).attr('rel') == 'all') {
        $(".reviews.list .review").show();
      } else if ($(this).attr('rel') == 'positive') {
        $(".reviews.list .review.negative").hide(); $(".reviews.list .review.positive").show();
      } else if ($(this).attr('rel') == 'negative') {
        $(".reviews.list .review.negative").show(); $(".reviews.list .review.positive").hide();
      }
    });

    // review form toggle
    $('li.review, div.review').map(function(){
      var review_form = $(this);
      var show        = $(this).find('.show_review');
      var edit        = $(this).find('.edit_review');

      show.find('a.edit').click(function(){
        show.hide(); edit.show(); edit.find('input.text').focus(); return false;
      });

      show.find('a.delete').restfulDelete({
        dataType: 'json',
        success: function(resp){ 
          $('.reviews.list').replaceWith(resp.html);
          enableReviewLinks('li.review, div.review');
          enableReviewForm('.review_form');
        }
      });

      edit.find('a.cancel').click(function(){
        show.show(); edit.hide(); return false;
      });
    });  
  };

  var enableReviewForm = function() {
    if(!LOGGED_IN) {
      // setup the cluetip link
      $('.cluetip_review_link').cluetip({
        local: true, 
        hideLocal: true, 
        arrows: true, 
        width: 350,  
        sticky: true,
        showTitle: false, 
        activation: 'click', 
        positionBy: 'auto',
        topOffset: 25,
        onShow: function(){ $.quickSignIn.setup(); }
      })
    }

    // review form ajax
    $('.review_form').submit(function(){
      var review_form = $(this);

      // send the review create/update
      $.ajax({
        type:    'post',
        url:     review_form.attr('action'),
        data:    review_form.serialize(),
        dataType: 'json',
        success: function(resp){
          if(resp.success) {
            if(resp.login_required) {
              review_form.find('.cluetip_review_link').click();
            } else { 
              $('.reviews.list').replaceWith(resp.html);
              enableReviewLinks('li.review, div.review');
              enableReviewForm('.review_form');
            };
          } else {
            review_form.find('.errors').html(resp.errors).show();
          }
        }
      });
      return false;
    });
  ;}
  
  // enable 'new review'/'edit review'/'all|positive|negative' links
  enableReviewLinks();

  // enable 'new review'/'edit review' form
  enableReviewForm();

  // REFACTOR with Events/live when we switch to JQuery 1.3
});

