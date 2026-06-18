SplitTimePicker = function(start_id, end_id) {
  this.init(start_id, end_id);
};

SplitTimePicker.prototype = {
  init: function(start_id, end_id) {
    this.target_start = $(start_id);
    this.target_end = $(end_id);
    this.start = this.buildSplitSelector(start_id, 'start');
    this.end = this.buildSplitSelector(end_id, 'end');
  },

  setStartEndTime: function(start_time, end_time) {
    this.setSplitTime(this.start, start_time);
    this.setSplitTime(this.end, end_time);
  },

  setSplitTime: function(selector, time) {
    var parts = time.split(":");
    var hour = parseInt(parts[0], 10);
    var min = parts[1];
    selector.ampm.val(hour < 12 || hour == 24 ? "AM" : "PM");
    selector.hour.val(hour % 12);
    selector.minute.val(min);
  },

  padZero: function(value) {
    value = parseInt(value, 10);
    return value >= 10 ? ""+value : "0"+value;
  },

  format12hr: function(value) {
    if(value == 12 || value == 0) return 12;
    if(value == 24) return "12";
    return value % 12;
  },

  buildSplitSelector: function(target_id, kind) {
    var target = $(target_id);
    var wrapper = $("<div class=\"hour-min-am-wrapper\">");
    var selectHours = $("<select class=\"select-hour\"/>");
    var selectMinutes = $("<select class=\"select-minute\"/>");
    var selectAmPm = $("<select class=\"select-am-pm\"/>");

    var options = "";
    for(var hour = 0; hour < 12; hour++) {
      options += "<option value=\""+hour+"\">"+this.format12hr(hour)+"</option>";
    }
    selectHours.html(options);

    options = "";
    var minutes = ["00", "15", "30", "45"];
    for(var i = 0; i < minutes.length; i++) {
      options += "<option value=\""+minutes[i]+"\">"+minutes[i]+"</option>";
    }
    selectMinutes.html(options);

    var am_pm_options = "";
    am_pm_options += "<option value=\"AM\">AM</option>";
    am_pm_options += "<option value=\"PM\">PM</option>";
    selectAmPm.html(am_pm_options);

    wrapper.append(selectHours);
    wrapper.append(selectMinutes);
    wrapper.append(selectAmPm);
    target.parent().append(wrapper);

    selectHours.on("change", this.loadSelectedTime.bind(this));
    selectMinutes.on("change", this.loadSelectedTime.bind(this));
    selectAmPm.on("change", this.loadSelectedTime.bind(this));

    return {hour: selectHours, minute: selectMinutes, ampm: selectAmPm, kind: kind, target: target};
  },

  parseSplitTime: function(element, am_as_24) {
    var hr = parseInt(element.hour.val(), 10);
    var mn = parseInt(element.minute.val(), 10);
    var pm = element.ampm.val();
    if (pm == 'AM' && am_as_24 && hr == 0) hr = 24;
    if (pm == 'PM') hr = hr + 12;
    return "" + this.padZero(hr)+":"+this.padZero(mn);
  },

  loadSelectedTime: function() {
    this.selected_start = this.parseSplitTime(this.start, false);
    this.selected_end = this.parseSplitTime(this.end, true);
    this.target_start.val(this.selected_start);
    this.target_end.val(this.selected_end);
  }
};
