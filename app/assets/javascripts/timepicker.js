TimePicker = function(start_id, end_id, picker, date_slots) {
  this.init(start_id, end_id, picker, date_slots);
};

TimePicker.prototype = {
  init: function(start_id, end_id, picker, date_slots) {
    this.target_start = $(start_id);
    this.target_end = $(end_id);
    this.date_slots = date_slots;
    this.picker = picker;
    this.start = this.buildSplitSelector(start_id, 'start');
    this.end = this.buildSplitSelector(end_id, 'end');
    var _self = this;
    if (picker) {
      picker.on("changeDate", function(e) { _self.dateSelected(); });
    }
    this.clearSplitSelector(this.start);
    this.clearSplitSelector(this.end);
  },

  setStartEndTime: function(start_time, end_time) {
    var parts = start_time.split(":");
    var hour = parseInt(parts[0], 10);
    var min = parts[1];
    this.dateSelected();
    var _self = this;
    _self.start.ampm.val(hour < 12 ? "AM" : "PM").trigger("change");
    _self.start.hour.val(hour).trigger("change");
    _self.start.minute.val(min).trigger("change");
    this.setEndTime(end_time);
  },

  setEndTime: function(end_time) {
    var parts = end_time.split(":");
    var hour = parseInt(parts[0], 10);
    var min = parts[1];
    this.selected_end = '';
    var _self = this;
    _self.end.ampm.val(hour < 12 ? "AM" : "PM").trigger("change");
    _self.end.hour.val(hour).trigger("change");
    _self.end.minute.val(min).trigger("change");
  },

  // ignore time zone
  dateToString: function(date) {
    return date.getFullYear() + '-' + this.padZero(date.getMonth() + 1) + '-' +  this.padZero(date.getDate());
  },

  padZero: function(value) {
    value = parseInt(value, 10);
    return value >= 10 ? ""+value : "0"+value;
  },

  checkAmPm: function(slot, pm) {
    if (pm == 'AM' && slot.start < '12:00') return true;
    if (pm == 'PM' && slot.end  >= '12:00') return true;
    return false;
  },

  format12hr: function(value) {
    if(value == 12 || value == 0) return 12;
    if(value == 24) return "12am";
    return value % 12;
  },

  buildSplitSelector: function(target_id, kind) {
    var target = $(target_id);
    var wrapper = $("<div class=\"hour-min-am-wrapper\">");
    var selectHours = $("<select class=\"select-hour\"/>");
    var selectMinutes = $("<select class=\"select-minute\"/>");
    var selectAmPm = $("<select class=\"select-am-pm\"/>");

    wrapper.append(selectHours);
    wrapper.append(selectMinutes);
    wrapper.append(selectAmPm);
    target.parent().append(wrapper);

    return {hour: selectHours, minute: selectMinutes, ampm: selectAmPm, kind: kind, target: target};
  },

  clearSplitSelector: function(source) {
    this.clearOneSelector(source.hour);
    this.clearOneSelector(source.minute);
    this.clearOneSelector(source.ampm);
  },

  clearOneSelector: function(source) {
    source.off("change").html("<option>--</option>");
  },

  parseSlot: function(str) {
    var parts = str.split(":");
    return {hour: parseInt(parts[0], 10), min: parseInt(parts[1], 10)};
  },

  getSelectedDate: function() {
    if (this.picker == null) {
      return "";
    } else {
      return this.dateToString(this.picker.datepicker("getDate"));
    }
  },

  selected_date: null,
  selected_slot: null,
  selected_start: '',
  selected_next: '',
  selected_end: '',

  getSelectedSlots: function() {
    if (this.date_slots == "ALLDAY") {
      return [{start: "00:00", end: "24:00"}];
    } else {
      return this.date_slots[this.selected_date];
    }
  },

  dateSelected: function() {
    this.clearSplitSelector(this.start);
    this.clearSplitSelector(this.end);

    this.selected_date = this.getSelectedDate();
    var slots = this.getSelectedSlots();
    if (!slots || slots.length == 0) return;

    var has_am = false, has_pm = false;
    for (var i = 0; i < slots.length; i++) {
      if (this.checkAmPm(slots[i], 'AM')) has_am = true;
      if (this.checkAmPm(slots[i], 'PM')) has_pm = true;
    }
    var am_pm_options = "";
    if (has_am) am_pm_options += "<option value=\"AM\">AM</option>";
    if (has_pm) am_pm_options += "<option value=\"PM\">PM</option>";

    var _self = this;
    this.start.ampm.html(am_pm_options).on("change", function() { _self.startAmPmChanged(); }).trigger("change");
  },

  startAmPmChanged: function() {
    this.clearSplitSelector(this.end);

    var slots = this.getSelectedSlots();
    var pm = this.start.ampm.val();

    var max_hour = pm == 'AM' ? 11 : 23;
    var min_hour = pm == 'AM' ? 0  : 12;
    var enabled_hours = [], hour, parsed_start, parsed_end;

    for(hour = 0 ; hour < 24; hour++) enabled_hours[hour] = false;
    for(hour = min_hour ; hour <= max_hour; hour++) {
      enabled_hours[hour] = false;
      for(i = 0; i < slots.length; i++) {
        parsed_start = this.parseSlot(slots[i].start);
        parsed_end   = this.parseSlot(slots[i].end);
        if(parsed_start.hour <= hour && hour < parsed_end.hour) {
          enabled_hours[hour] = true;
          break;
        }
      }
    }

    // cut last disabled hours like first disabled
    while(max_hour > min_hour  && !enabled_hours[max_hour]) max_hour -= 1;
    while(min_hour <= max_hour && !enabled_hours[min_hour]) min_hour += 1;

    var options = "";
    var first = -1;
    for(hour = min_hour; hour <= max_hour; hour++) {
      if(enabled_hours[hour]) {
        if (first < 0) first = hour;
        options += "<option value=\""+hour+"\">"+this.format12hr(hour)+"</option>";
      } else {
        options += "<option disabled value=\""+hour+"\">"+this.format12hr(hour)+"</option>";
      }
    }
    var _self = this;
    this.start.hour.html(options).val(first).on("change", function() { _self.startHourSelected(); }).trigger("change");
  },

  startHourSelected: function() {
    this.clearSplitSelector(this.end);
    var slots = this.getSelectedSlots();

    var minutes = ["00", "15", "30", "45"];
    var hour = this.padZero(this.start.hour.val());
    var options = "";
    var first = -1;
    for(var i = 0; i < minutes.length; i++) {
      var time = hour + ":" + minutes[i];
      var time_plus_1 = this.padZero(parseInt(hour, 10)+1)+":"+minutes[i];
      var enabled = false;
      for(var j = 0; j < slots.length; j++) {
        if(slots[j].start <= time && time < slots[j].end && time_plus_1 <= slots[j].end) {
          enabled = true;
          if (first < 0) first = minutes[i];
          break;
        }
      }
      if (enabled) {
        options += "<option value=\""+minutes[i]+"\" "+(enabled ? "" : "disabled")+">"+minutes[i]+"</option>";
      }
    }

    var _self = this;
    this.start.minute.html(options).val(first).on("change", function() { _self.startMinuteSelected(); }).trigger("change");
  },

  startMinuteSelected: function() {
    this.clearSplitSelector(this.end);
    var slots = this.getSelectedSlots();

    var hour = this.padZero(this.start.hour.val());
    var minute = this.padZero(this.start.minute.val());
    var time = hour + ":" + minute;
    var next_hour = 1 + parseInt(hour, 10);
    for(var j = 0; j < slots.length; j++) {
      if(slots[j].start <= time && time < slots[j].end) {
        this.selected_slot  = slots[j];
        this.selected_start = time;
        this.selected_next  = "" + this.padZero(next_hour) + ":" + minute;
        break;
      }
    }

    var options = "";
    if (next_hour < 12) options += "<option value=\"AM\">AM</option>";
    if (this.selected_slot.end >= '12:00') options += "<option value=\"PM\">PM</option>";

    var _self = this;
    var sel_end = this.selected_end;
    var keep_end = this.date_slots == 'ALLDAY' && this.selected_end && this.selected_next <= this.selected_end;
    this.end.ampm.html(options).on("change", function() { _self.endAmPmSelected(); }).trigger("change");
    if (keep_end) this.setEndTime(sel_end);
  },

  endAmPmSelected: function() {
    this.clearOneSelector(this.end.hour);
    this.clearOneSelector(this.end.minute);

    var pm = this.end.ampm.val();
    var max_hour = pm == 'AM' ? 11 : 24;
    var min_hour = pm == 'AM' ? 0  : 12;

    var enabled_hours = [], hour;
    var parsed_start = this.parseSlot(this.selected_start);
    var parsed_end = this.parseSlot(this.selected_slot.end);
    if (min_hour < parsed_start.hour + 1) min_hour = parsed_start.hour + 1;

    for(hour = 0 ; hour <= 24; hour++) enabled_hours[hour] = false;
    for(hour = min_hour ; hour <= max_hour; hour++) {
      if(parsed_start.hour < hour && hour <= parsed_end.hour) {
        enabled_hours[hour] = true;
      }
    }

    // cut last disabled hours like first disabled
    while(max_hour >  min_hour && !enabled_hours[max_hour]) max_hour -= 1;
    while(min_hour <= max_hour && !enabled_hours[min_hour]) min_hour += 1;

    var options = "";
    var first = -1;
    for(hour = min_hour; hour <= max_hour; hour++) {
      if(enabled_hours[hour]) {
        if (first < 0) first = hour;
        options += "<option value=\""+hour+"\">"+this.format12hr(hour)+"</option>";
      } else {
        options += "<option disabled value=\""+hour+"\">"+this.format12hr(hour)+"</option>";
      }
    }

    var _self = this;
    this.end.hour.html(options).val(first).on("change", function() { _self.endHourSelected(); }).trigger("change");
  },

  endHourSelected: function() {
    var prev_minutes = $(this.end.minute).val();
    this.clearOneSelector(this.end.minute);

    var minutes = ["00", "15", "30", "45"];
    var hour = this.padZero(this.end.hour.val());
    var options = "";
    var first = -1;
    for(var i = 0; i < minutes.length; i++) {
      var time = hour + ":" + minutes[i];
      var enabled = false;
      if(this.selected_next <= time && time <= this.selected_slot.end) {
        enabled = true;
        if (first < 0 || minutes[i] == prev_minutes) first = minutes[i];
      }
      if (enabled) {
        options += "<option value=\""+minutes[i]+"\" "+(enabled ? "" : "disabled")+">"+minutes[i]+"</option>";
      }
    }

    var _self = this;
    this.end.minute.html(options).val(first).on("change", function() { _self.endMinuteSelected(); }).trigger("change");
  },

  endMinuteSelected: function() {
    var hour = this.padZero(this.end.hour.val());
    var minute = this.padZero(this.end.minute.val());
    var time = hour+":"+minute;
    this.selected_end = time;
    this.target_start.val((this.selected_date + " " + this.selected_start).trim());
    this.target_end.val((this.selected_date + " " + this.selected_end).trim());
  }
};
