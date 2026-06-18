window.ST = window.ST || {};

(function(module) {
  var additionalListingsSelector = '#additional-listings',
    buttonSelector = '#additional-listings-button';

  var init = function(options) {
    var spinner = $(buttonSelector + ' .spinner');
    $(document).on('ajax:send', buttonSelector, function() {
      spinner.removeClass('hidden');
    });
    $(document).on('ajax:complete', buttonSelector, function() {
      spinner.addClass('hidden');
    });
  };

  var nextPage = function(options) {
    $(additionalListingsSelector).append(options.content);
    if (options.next_page) {
      $(buttonSelector).attr('href', options.next_page_path);
    } else {
      $(buttonSelector).hide();
    }
  };

  module.transactionShow = {
    init: init,
    nextPage: nextPage,
  };
})(window.ST);
