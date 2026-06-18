module AvailabilitySearchService
  module_function

  # Possible availability management by unit type
  BOOKING_MODES_BY_UNIT = {
    'hour'     => ['none', 'hour'],
    '1/2 hour' => ['none', 'hour'],
    '4 hours'  => ['none', 'hour'],
    '8 hours'  => ['none', 'hour'],

    'day'      => ['none', 'day'],
    'night'    => ['none', 'night'],

    'week'     => ['none', 'day', 'night'],

    'activity' => ['none', 'hour', 'day'],
    'person'   => ['none', 'hour', 'day'],

    '24 hours' => ['none', 'night'],

    'person & up' => ['none', 'hour', 'day'],
    'activity & up' => ['none', 'hour', 'day'],
    'tour & up' => ['none', 'hour', 'day'],
    'item & up' => ['none'],
  }

  # [booking_mode][unit_name]
  PRICING_BY_BOOKING_MODE = {
    'none' => nil,

    'hour' => {
      'hour'     => {mode: :duration, factor: 1},
      '1/2 hour' => {mode: :duration, factor: 0.5},
      '4 hours'  => {mode: :duration, factor: 4},
      '8 hours'  => {mode: :duration, factor: 8},
      'person'   => {mode: :quantity},
      'activity' => {mode: :quantity},
      'person & up' => {mode: :quantity},
      'activity & up' => {mode: :quantity},
      'tour & up' => {mode: :quantity},
      'item & up' => {mode: :quantity},
    },

    'day'  => {
      'day'      => {mode: :duration, factor: 1},
      'week'     => {mode: :duration, factor: 7},
      'activity' => {mode: :quantity},
      'person'   => {mode: :quantity},
      'person & up' => {mode: :quantity},
      'activity & up' => {mode: :quantity},
      'tour & up' => {mode: :quantity},
      'item & up' => {mode: :quantity},
    },

    'night'  => {
      'night'    => {mode: :duration, factor: 1},
      '24 hours' => {mode: :duration, factor: 1},
      'week'     => {mode: :duration, factor: 7},
    }
  }

end
