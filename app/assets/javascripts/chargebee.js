window.ST = window.ST || {};
window.ST.chargebee = (function(module) {
  var chargebeeInstance;
  var options;

  var openCheckout = function() {
    var data = {person_id: options.person_id};
    $('#cb-loader').show();
    $('#error-container').hide();
    chargebeeInstance.openCheckout({
      hostedPage: function() {
        // We will discuss on how to implement this end point in the next step.
        return $.ajax({
          url: options.generateHostedPagePath + '?period_unit=' + $('#period_unit').val(),
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

  var init = function (_options) {
    options = _options;
    $(document).ready(function() {
      chargebeeInstance = Chargebee.init({
        site: options.site,
        iframeOnly: true
      });
      openCheckout();
      $('#chargebee_submit').click(function(e) {
        e.preventDefault();
        openCheckout();
      });
    });
  };

  return {
    init: init,
  }
})(window.ST);

