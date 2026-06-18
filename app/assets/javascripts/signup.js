window.ST = window.ST || {};
window.ST.signup = (function(module) {
  var chargebeeInstance;
  var options;

  var onRailsSubmit = function(e) {
    $('#cb-loader').show();
    $('#error-container').hide();
  };

  var init = function (_options) {
    options = _options;
    $(document).on('ajax:before', '#chargebee-checkout', onRailsSubmit);
    $(document).ready(function() {
      $("#person_phone_number").inputmask({alias: 'phone'});
      $('#chargebee-checkout').validate();
    });
  };

  var createPerson = function(params) {
    if (params.errors) {
      $('#chargebee-checkout').replaceWith(params.content);
      $("#person_phone_number").inputmask({alias: 'phone'});
      $('#chargebee-checkout').validate();
    } else {
      location.href = options.successPath + '?period_unit=' + params.period_unit;
    }
  }

  return {
    init: init,
    createPerson: createPerson,
  }
})(window.ST);

