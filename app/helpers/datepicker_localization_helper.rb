module DatepickerLocalizationHelper

  def datepicker_localized_dates
    days = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    months = [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]
    translated_days = days.map { |day_symbol| I18n.t("datepicker.days.#{day_symbol}") }
    translated_days_short = days.map { |day_symbol| I18n.t("datepicker.days_short.#{day_symbol}") }
    translated_days_min = days.map { |day_symbol| I18n.t("datepicker.days_min.#{day_symbol}") }
    translated_months = months.map { |day_symbol| I18n.t("datepicker.months.#{day_symbol}") }
    translated_months_short = months.map { |day_symbol| I18n.t("datepicker.months_short.#{day_symbol}") }
    {
      days: translated_days,
      daysShort: translated_days_short,
      daysMin: translated_days_min,
      months: translated_months,
      monthsShort: translated_months_short,
      today: I18n.t("datepicker.today"),
      weekStart: I18n.t("datepicker.week_start", default: 0),
      clear: I18n.t("datepicker.clear"),
      format: I18n.t("datepicker.format"),
      close: I18n.t("datepicker.close")
    }
  end
end
