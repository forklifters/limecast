$(document).ready(function() {
  $(".audio_player .url").map(function(){
    var flashvars = {
      soundFile: $(this).attr('href')
    };

    var movie = $("<span />").flash({
      src:       "/flash/player.swf",
      width:     290,
      height:    24,
      flashvars: flashvars
    });

    $(this).parent().append(movie);

    return false;
  });
});
