module HomepageHelper
  def show_subcategory_list(category, current_category_id)
    category.id == current_category_id || category.children.any? do |child_category|
      child_category.id == current_category_id
    end
  end

  def with_first_listing_image(listing, &block)
    image = listing&.listing_images&.first
    url = if image.is_a?(ListingIndexViewUtils::ListingImage)
      image[:small_3x2]
    elsif image.is_a?(ListingImage)
      image.image.url(:small_3x2)
    end
    block.call(url) if url
  end

  def without_listing_image(listing, &block)
    if listing.listing_images.size == 0
      block.call
    end
  end

  def format_distance(distance)
    precision = (distance < 1) ? 1 : 2
    (distance < 0.1) ? "< #{number_with_delimiter(0.1, locale: locale)}" : number_with_precision(distance, precision: precision, significant: true, locale: locale)
  end

  DEFAULT_SORT_ORDER = 'sort_date_desc'

  def sorting_options(selected_value)
    sort_data = ListingIndexService::DataTypes::SORTING_OPTIONS.map{|value, sql| [t("homepage.sorting.#{value}"), value]}
    options_for_select(sort_data, selected_value.present? ? selected_value : DEFAULT_SORT_ORDER)
  end

  def ext_path_to_listing(listing: , make_url: false, referral_id: nil)
    ready_path = make_url ? listing_url(listing.url, referral_id: referral_id) : listing_path(listing.url)
    if @current_user && @current_user.has_admin_rights?(@current_community)
      ready_path
    elsif listing.ext_booking_url.present? && listing.ext_booking_url_direct
      listing.ext_booking_url
    else
      ready_path
    end
  end
end
