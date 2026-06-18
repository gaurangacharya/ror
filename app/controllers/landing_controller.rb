class LandingController < ApplicationController
  layout "application"

  def index
    @skip_app_styles = true
    @no_top_search = true
    flash.clear
    @featured_listings = Listing.where(community_id: @current_community.id, deleted: false, featured: true).order('rand()')
    @community_customization = @current_community.community_customizations.where(locale: I18n.locale).first
    @reviews = Review.where(community: @current_community)
  end
end
