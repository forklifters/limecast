$(document).ready(function(){
  $('form#new_feed').submit(function(){

    var poll_for_status = function(response) {
      var feed_url = $('#feed_url').attr('value');

      // clone the disabled form and append it
      var form_clone = $('#added_podcast').clone();
      form_clone.attr('id', null);
      form_clone.find('input[value=Add]').attr('disabled', 'disabled').unbind('click');
      form_clone.find('.text').attr('value', feed_url);
      form_clone.show();
      $('#added_podcast_list').append(form_clone);

      // reset the form
      $('#new_feed').hide();
      $('#feed_url').unbind().val("").blur(); // unbind the jquery.default-text.js stuff, set val to empty, and blur it so focus works

      // FIX
      // if($('#inline_signin'))
      //   $('#inline_signin').show();

      var periodic_count = 0; 
      $.periodic(function(controller){
        var callback = function(response) {
          periodic_count += 1;
          form_clone.find('.status').html(response);
          if(/finished/g.test(response)) {
            controller.stop();
            $('#new_feed').show();
            $('#feed_url').focus();
          } else if(periodic_count > 20) {
            controller.stop();
            $('#new_feed').show();
            $('#feed_url').focus();
            form_clone.find('.status').html('<p class="status_message">Timeout error. Please try again.</p>');
          }
        };

        $.ajax({
          url:      '/status',
          type:     'post',
          data:     {feed: feed_url},
          dataType: 'html',
          success:  callback,
          error:    callback
        });

        return true;
      }, {frequency: 2});
    };

    $.ajax({
      data:     $(this).serialize(),
      dataType: 'script',
      type:     'post',
      url:      '/feeds',
      success:  poll_for_status
    });
    // Keep form from submitting
    return false;
  });
});

