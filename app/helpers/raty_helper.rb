module RatyHelper
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def stars_rating_tag(average, options={})
    if average < 1 && options[:readonly]
      return
    end
    dimension    = "quality"
    read_only    = !!options[:readonly]
    show_quantity= options[:show_quantity]|| false
    star         = options[:star]         || 5
    enable_half  = options[:enable_half]  || false
    half_show    = options[:half_show]    || false
    star_path    = options[:star_path]    || "/assets"
    star_on      = options[:star_on]      || "star-db.png"
    star_off     = options[:star_off]     || "star-c3.png"
    star_half    = options[:star_half]    || "star-half-db-c3.png"
    cancel       = options[:cancel]       || false
    cancel_place = options[:cancel_place] || "left"
    cancel_hint  = options[:cancel_hint]  || "Cancel current rating!"
    cancel_on    = options[:cancel_on]    || "cancel-on.png"
    cancel_off   = options[:cancel_off]   || "cancel-off.png"
    no_rated_msg = options[:noRatedMsg]   || "I am read-only and I haven't rated yet!"
    # round        = options[:round]        || { down: .26, full: .6, up: .76 }
    space        = options[:space]        || false
    single       = options[:single]       || false
    target       = options[:target]       || ''
    target_text  = options[:targetText]   || ''
    target_type  = options[:targetType]   || 'hint'
    target_format = options[:targetFormat] || '{score}'
    target_score  = options[:targetScore]  || '#non-existing'
    score_name    = options[:scoreName]    || 'DETACHED'
    average_as_default = options[:averageAsDefault].nil? ? true : !!options[:averageAsDefault]

    disable_after_rate = options[:disable_after_rate] && true
    disable_after_rate = true if disable_after_rate.nil?

    total_quantity = show_quantity ? quantity : false

    html_class   = options[:class] || ''
    html_base_class = "star"
    html_class = html_class.present? ? "#{html_base_class} #{html_class}" : html_base_class

    content_tag :div, '',
      :class => html_class,
      "data-dimension" => dimension,
      "data-rating" => (average_as_default ? average : nil),
      "data-disable-after-rate" => disable_after_rate,
      "data-readonly" => read_only,
      "data-enable-half" => enable_half,
      "data-half-show" => half_show,
      "data-star-count" => star,
      "data-star-path" => star_path,
      "data-star-on" => star_on,
      "data-star-off" => star_off,
      "data-star-half" => star_half,
      "data-cancel" => cancel,
      "data-cancel-place" => cancel_place,
      "data-cancel-hint"  => cancel_hint,
      "data-cancel-on" => cancel_on,
      "data-cancel-off" => cancel_off,
      "data-no-rated-message" => no_rated_msg,
      # "data-round" => round,
      "data-space" => false,
      "data-single" => single,
      "data-target" => target,
      "data-target-text" => target_text,
      "data-target-type" => target_type,
      "data-target-format" => target_format,
      "data-target-score" => target_score,
      "data-score-name" => score_name,
      "data-url-transaction" => '/',
      "data-quantity" => total_quantity
  end
end
