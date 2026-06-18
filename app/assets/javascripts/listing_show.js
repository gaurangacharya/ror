window.ST = window.ST || {};

(function(module) {
  var startSelector = '#listing_working_time_slot_start_time',
    endSelector = '#listing_working_time_slot_end_time';

  var newSlot = function(options) {
    $('#wrap-working-time-slot').html(options.content);
    $('#working_time_slot_lightbox').lightbox_me({centered: true, zIndex: 1000000});
    setupDatepicker(options);
    $(startSelector).on('change', function() {
      var selected = $(this).find('option:selected'),
        startTimeindex = selected.data('index'),
        endTime = $(endSelector);
      setUpSelectOptions(options, 'end');
      endTime.find('option').each(function () {
        var option = $(this), endTimeIndex = option.data('index');
        if (endTimeIndex > startTimeindex) {
          option.removeAttr('disabled');
        } else {
          option.prop('disabled', true);
        }
      });

    });
    // update calendar to show created slots when request to create on multiple dates partially failed
    if(options.update_calendar) {
      fetchCalendar(); 
    }
  };

  var editSlot = function(options) {
    options.multidate = false;
    newSlot(options);
    setUpSelectOptions(options, 'start');
    setUpSelectOptions(options, 'end');
  };

  var selectedDateTime = function(selector) {
    var value = $(selector).val().substr(0,16);
    return value.length > 0 ? value : null;
  };

  var dateAtBeginningOfDay = function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0);
  };

  var setupDatepicker = function(options) {
    $.fn.datepicker.dates[options.datepicker.locale] = options.datepicker.localized_dates;
    var picker = $('#listing_working_time_slot_date').datepicker({
      language: options.datepicker.locale,
      startDate: (options.edit ? null : dateAtBeginningOfDay(new Date())),
      autoclose: !options.multidate,
      multidate: options.multidate,
      clearClose: options.multidate,
      clearBtn: options.multidate,
      multidateSeparator: ',  ',
      weekStart: 0
    });
    picker.on('changeDate', function(e) {
      setUpSelectOptions(options, 'start');
    });
    if(options.new_slot_date) {
      setUpSelectOptions(options, 'start');
    }
  };

  var setUpSelectOptions = function(options, elName) {
    var selectOne = ST.t('listings.listing_actions.select_one'),
      date_options = options.time_slot_options,
      options_for_select,
      date = moment($('#listing_working_time_slot_date').datepicker('getUTCDate'))
        .format('YYYY-MM-DD'),
      element, selectedOption = null;

    if (options.edit) {
      selectedOption = selectedDateTime(elName === 'start' ? '#selected_start_time' : '#selected_end_time');
    }
    options_for_select = ['<option value="" disabled ' + (selectedOption ? '' : 'selected ') +
      ' >' + selectOne + '</option>'];

    for(var index in date_options) {
      var option = date_options[index],
        value = date + ' ' + option.value,
        selected = (selectedOption && selectedOption === value) ? 'selected ' : '';
      options_for_select.push('<option value="' + value + '" data-index="' + index +
        '" ' + selected + ' >' + option.label + '</option>');
    }

    if (elName == 'start') {
      element = $(startSelector);
      $(endSelector).html('');
    } else {
      element = $(endSelector);
    }
    element.html($(options_for_select.join('')));
  };

  var setupCalendar = function(options) {
    var defaultDate = dateAtBeginningOfDay(new Date());
    var timeOptions = {
      displayEventEnd: true, timeFormat: "h(:mm)a", allDaySlot: false, slotLabelFormat: "h(:mm)a"
    };
    var renderer = null;
    if(options.daily) {
      timeOptions = { 
        displayEventEnd: false, timeFormat: "h(:mm)a", allDaySlot: true, slotLabelFormat: "h(:mm)a", displayEventStart: false
      };
    }
    $('#calendar').fullCalendar({
      header: {
        left: (options.daily ? 'prev' : 'prev,next today'),
        center: 'title',
        right: (options.daily ? 'next' : 'month,agendaWeek,agendaDay,listWeek')
      },
      allDayDefault: options.daily,
      defaultDate: defaultDate,
      navLinks: !options.daily,
      eventLimit: true,
      dayClick: function(date, jsEvent, view) {
        $.getScript(options.new_slot_path+"?date="+date.format("YYYY-MM-DD"));
      },
      eventSources: [
        {
          url: options.working_time_slots_path,
          className: options.daily ? null : 'cal-working-time-slots'
        },
        {
          url: options.booked_time_slots_path,
          className: 'cal-booked-time-slots'
        }
      ],
      views: { month: timeOptions, basic: timeOptions, agenda: timeOptions, week: timeOptions, day: timeOptions },
      eventAfterRender: renderer,
      locale: options.locale,
      firstDay: 0
    });
  };

  var fetchCalendar = function() {
    $('#calendar').fullCalendar('refetchEvents');
  };

  var slotCreated = function(options) {
    $('#working_time_slot_lightbox').trigger('close');
    fetchCalendar();
  };

  var slotUpdated = function(options) {
    slotCreated(options);
  };

  var setupSmallCalendar = function(options) {
    var defaultDate = dateAtBeginningOfDay(new Date());
    $('#calendar').fullCalendar({
      header: {
        left: 'prev',
        center: 'title',
        right: 'next'
      },
      defaultDate: defaultDate,
      navLinks: false,
      eventLimit: true,
      eventSources: [
        {
          url: options.time_slots_path
        }
      ],
      locale: options.locale,
      eventAfterRender: (options.daily ? null : function(event, view) {
        var date = event.start.format("YYYY-MM-DD");
        var prefix = event.className == 'day-availability-free' || event.className == 'day-availability-partial' ? options.prefix +"<br/>" : ""
        $("td[data-date="+date+"]").attr('title', prefix+event.description);
      }),
      height: 'auto',
      firstDay: 0
    });
    $(document).on("mouseover", "td[data-date]", function() {
      $(this).tipsy({gravity: 's', html: true}).tipsy("show");
    });
    $(document).on("click", "td[data-date]", function() {
      $(this).tipsy({gravity: 's', html: true}).tipsy("show");
    });
  };


  module.listingShow = {
    newSlot: newSlot,
    editSlot: editSlot,
    setupCalendar: setupCalendar,
    setupSmallCalendar: setupSmallCalendar,
    slotCreated: slotCreated,
    slotUpdated: slotUpdated
  };
})(window.ST);
