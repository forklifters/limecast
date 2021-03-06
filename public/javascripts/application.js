$.ajaxSetup({
  'beforeSend': function(xhr) { xhr.setRequestHeader("Accept", "text/javascript")}
})

// Method hooks up all of the input text boxes that should have default labels
function defaultText() {
  $("#podcast_url, #accounts_forgot_password #email, #search_podcast_s, " + 
    "#query, #user_tagging_tag_string, .review_form input[type=text], .review_form textarea").inputDefaultText();
}

// Handles truncated "more" and "less" links
function truncatedText() {
  $("a.truncated").click(function(){
    var text = $(this).text();
    var oppositeText = text == "less" ? "more" : "less";

    $(this).text(oppositeText);
    $(this).parent().find(".truncated." + oppositeText).hide();
    $(this).parent().find(".truncated." + text).show();

    return false;
  }); 
}

function favoriteLink() {
  $('a.favorite').click(function() {
    var link = $(this);

    $.post(link.attr('href'), {}, function(resp) { 
      if(resp.logged_in) {
        window.location.reload();
      } else {
        link.authTmpSetup();
      } 
    }, 'json');
    return false;
  });
}

function setupCluetips() {
  var default_options = { local: true, arrows: true, width: 350, showTitle: false };
  $('a.tips').cluetip(default_options);
  
  if(!LOGGED_IN) {
    // $.extend(default_options, {activation: 'click', sticky: true, onShow: function(){$.quickSignIn.setup()}});

    $.extend(default_options, {positionBy: 'auto', leftOffset: -10});
    $('#podcast_tag_form_cluetip_link').cluetip(default_options);
    
    $.extend(default_options, {positionBy: 'bottomTop', topOffset: 25});
    $('a.login').cluetip(default_options); 
    $('a.favorite_link').cluetip(default_options); 
    $('a.unfavorite_link').cluetip(default_options); 

    $.extend(default_options, {positionBy: 'bottomTop'});
    $('a.cluetip_add_link').cluetip(default_options);

    $.extend(default_options, {height: 350, onShow: function(){$.quickSignIn.showSignUp(); $.quickSignIn.setup();}});
    $('a.signup').cluetip(default_options);
  }
}

function setupAuth() {
  $("#auth form").authSetup();
  $("#auth_link").authLink();
  $("#sign_out_link").signoutSetup();
}

function setupTabs() {
  $('.tabify').tabs({ navClass: 'tabs', containerClass: 'tabs-cont' });
}

function toggleLinks() {
  $('a.toggle').mousedown(function(){
    $(this).html($(this).html()=='▼'?'►':'▼').parents('li').toggleClass('closed');
    var preview = $(this).parents('li').find('p.preview');
    if(preview.length > 0) { hook_up_preview(preview); }
    return false;
  }).click(function(){return false;});
}

function editLinks() {
  $('#edit a.edit').mousedown(function(){
    $(this).hide().parent().find('form').show();
  }).click(function(){return false;});
  $('#edit button.cancel').mousedown(function(){
    $(this).parents('form').hide().parent().find('a.edit').show();
  }).click(function(){return false;});
}

function reviewLinks() {
  $('#reviews nav a').mousedown(function(){ $('#reviews ul').removeClass().addClass($(this).attr('class')); }).click(function(){return false;});
  $('#reviews li a.edit').mousedown(function(){ $(this).parents('li.review').addClass('editing'); }).click(function(){return false;});
  $('#reviews li a.delete').restfulDelete({
    dataType: 'json',
    success: function(resp){ 
      $('#reviews ul').html(resp.html);
      reviewLinks(); 
    }
  });
  $('#reviews li a.cancel').mousedown(function(){ $(this).parents('li.review').removeClass('editing'); }).click(function(){return false;});
  $('#reviews form, #review form').submit(function(event){ 
    var form = $(this);
    $.post(form.attr('action'), form.serialize(), function(resp){ 
      if(resp.success) {
        if(resp.login_required) { 
          form.authTmpSetup();
        } else { 
          $('#reviews ul').html(resp.html); 
          form.remove();
          reviewLinks(); 
          $("#review_body, #review_title").inputDefaultText();
        }
      } else form.find('.errors').html(resp.errors).show();
    }, 'json');
    return false;
  });
}

function setupTabs() {
  $('#user, #results').tabs();
}

function setupSurf() {
  $('#surf button.next').click(function(){
    $.post('/surf/next', {'episode_id': $(this).attr('rel')}, function(resp){
      $("#surf").html(resp);
      $("#surf").find('.video').initVideo();
      setupSurf();
    });
  });
  $('#surf button.previous').click(function(){
    $.post('/surf/previous', {'episode_id': $(this).attr('rel')}, function(resp){
      $('#surf').html(resp).find('.video').initVideo();
      setupSurf();
    });
  });
}

$(function() {
  defaultText();
  truncatedText();
  favoriteLink();
  toggleLinks();
  reviewLinks();
  editLinks();
  setupAuth();
  setupTabs();
  setupSurf();
});
