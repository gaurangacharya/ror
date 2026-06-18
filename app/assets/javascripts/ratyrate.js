$.fn.raty.defaults.half = false;
$.fn.raty.defaults.halfShow = true;
$.fn.raty.defaults.path = "/assets";
$.fn.raty.defaults.cancel = false;

var initRatings = function() {
  $(".star:not(.has-raty)").each(function() {
    $(this).addClass("has-raty");
    var $readonly = ($(this).attr('data-readonly') == 'true');
    var $quantity = $(this).attr('data-quantity');
    var $half     = ($(this).attr('data-enable-half') == 'true');
    var $halfShow = ($(this).attr('data-half-show') == 'true');
    var $single   = ($(this).attr('data-single') == 'true');
    var $rate_url = $(this).attr('data-url-transaction');
    $(this).raty({
      score: function() {
        return $(this).attr('data-rating')
      },
      number: function() {
        return $(this).attr('data-star-count')
      },
      half:         $half,
      halfShow:     $halfShow,
      single:       $single,
      path:         $(this).attr('data-star-path'),
      starType:     'i',
      starOn:       $(this).attr('data-star-on'),
      starOff:      $(this).attr('data-star-off'),
      starHalf:     $(this).attr('data-star-half'),
      cancel:       ($(this).attr('data-cancel') == 'true'),
      cancelPlace:  $(this).attr('data-cancel-place'),
      cancelHint:   $(this).attr('data-cancel-hint'),
      cancelOn:     $(this).attr('data-cancel-on'),
      cancelOff:    $(this).attr('data-cancel-off'),
      noRatedMsg:   $(this).attr('data-no-rated-message'),
      round:        $(this).attr('data-round'),
      space:        ($(this).attr('data-space') == 'true'),
      target:       $(this).attr('data-target'),
      targetText:   $(this).attr('data-target-text'),
      targetType:   $(this).attr('data-target-type'),
      targetFormat: $(this).attr('data-target-format'),
      targetScore:  $(this).attr('data-target-score'),
      scoreName:    $(this).attr('data-score-name'),
      readOnly: $readonly,
      //click: function(score, evt) {
      //  var _this = this;
      //  if (score == null) { score = 0; }
      //}
    });
    if ($quantity != "false") {
      $(this).append(' (' + $quantity + ')');
    }
  });
};
