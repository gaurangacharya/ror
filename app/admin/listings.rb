ActiveAdmin.register(Listing) do
  actions :index, :show
  action_item :close_open, only: :show do
    if resource.open?
      link_to 'Close', close_admin_panel_listing_path(resource),  method: :put
    else
      link_to 'Open', open_admin_panel_listing_path(resource),  method: :put
    end
  end

  action_item :reimport_fareharbor, only: :show do
    link_to 'Re-import from Fareharbor', reimport_fareharbor_admin_panel_listing_path(resource),  method: :put
  end

  member_action :close, method: :put do
    resource.open = false
    resource.save
    redirect_to resource_path, notice: "Closed!"
  end

  member_action :open, method: :put do
    resource.open = true
    resource.save
    redirect_to resource_path, notice: "Opened!"
  end

  member_action :reimport_fareharbor, method: :put do
    FareharborImportListing.perform_later(@current_community.id, resource.id)
    redirect_to resource_path, notice: "Re-import from Fareharbor scheduled!"
  end

  filter :title
  filter :author_id, as: :search_select_filter,
    url: proc { search_admin_panel_authors_path },
    display_name: 'long_name', minimum_input_length: 3,
    fields: [:username, :given_name, :family_name, :display_name, :emails_address],
    order_by: 'username_asc'
  filter :created_at
  filter :updated_at
  filter :fareharbor_updated_at

  scope :open_and_valid_now
  scope :closed
  scope :fareharbor_in_extended_url
  scope :fareharbor_import_since_yesterday

  index do
    selectable_column
    id_column
    column :open
    column :title
    column :price
    column :author do |listing|
      #link_to listing.author.username, "/en/#{listing.author.username}"
      link_to listing.author.username, admin_panel_person_path(listing.author.username)
    end
    column :category do |listing|
      listing.category.display_name(:en)
    end
    #actions
    column :actions do |listing|
      links = []
      links << link_to('View', admin_panel_listing_path(listing))
      if listing.open?
        links << link_to('Close', close_admin_panel_listing_path(listing),
          method: :put, data: { confirm: 'Are you sure?' })
      else
        links << link_to('Open', open_admin_panel_listing_path(listing),
          method: :put, data: { confirm: 'Are you sure?' })
      end
      links << link_to('View in site', listing_path(listing.url))
      links.join(' ').html_safe
    end
  end

  show do
    attributes_table do
      row :open
      row :title do |listing|
        link_to listing.title, listing_path(listing.url)
      end
      row :price
      row :author do |listing|
        link_to listing.author.username, admin_panel_person_path(listing.author.username)
      end
      row :author_in_site do |listing|
        link_to listing.author.display_name, "/en/#{listing.author.username}"
      end
      row :category do |listing|
        listing.category.display_name(:en)
      end
      row :description
      row :description_from_provider
      row :description_closing
      row :featured
      row :call_for_price
      row :ext_booking_url
      row :instant_booking
      row :guest_only
      row :admin_rating
      row :restaurant
      row :restaurant_price
      row :pdf
      row :embed_document
      row :ext_booking_url_direct
      row :musement_widget_id
      row :fareharbor_company_id
      row :fareharbor_item_id
      row :fareharbor_updated_at
      row :hide_price
      row :location do |listing|
        if listing.location
          table_for listing.location do
            column :address
            column :latitude
            column :longitude
          end
        end
      end

      row :created_at
      row :updated_at
    end
    #active_admin_comments
  end
end
