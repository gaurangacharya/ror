window.ST = window.ST || {};
window.ST.profile = (function(module) {
  var options;
  var chargebeeInstance;

  var openCheckout = function(params) {
    var data = {person_id: options.person_id};
    $('#cb-loader').show();
    $('#error-container').hide();
    chargebeeInstance.openCheckout({
      hostedPage: function() {
        // We will discuss on how to implement this end point in the next step.
        return $.ajax({
          url: options.generateHostedPagePath + '?plan_id=' + params.plan_id + '&period_unit=' + params.period_unit,
          data: data,
          method: 'POST'
        });
      },
      loaded: function() {
        console.log('chargebee checkout opened');
      },
      error: function() {
        $('#cb-loader').hide();
        $('#error-container').show();
      },
      close: function() {
        $('#cb-loader').hide();
        $('#error-container').hide();
        console.log('chargebee checkout closed');
      },
      success: function(hostedPageId) {
        // success callback
        console.log('chargebee hostedPageId=' + hostedPageId);
        location.href = options.successPath;
      },
      step: function(value) {
        // value -> which step in checkout
        console.log('chargebee step=' + value);
      }
    });
  };

  var startUpgrade = function(e) {
    e.preventDefault();
    $('#upgrade-plan-popup').trigger('close');
    openCheckout({
      plan_id: $('#plan_id').val(),
      period_unit: $('#period_unit').val()
    });
  }

  var initPopup = function() {
    $(document).on('click', '.chargebee-upgrade-plan', startUpgrade);
    $('.show-popup').on('click', function() {
      $('#upgrade-plan-popup').lightbox_me({centered: true, closeSelector: '#close_x, #close_x1'});
    });
  };

  var init = function(_options) {
    options = _options;
    $(document).ready(function() {
      chargebeeInstance = Chargebee.init({
        site: options.site
      });
      initPopup();
    });
  };

  return {
    init: init,
  }
})(window.ST);

