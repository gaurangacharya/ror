ActiveAdmin.register(FareharborCompany) do
  actions :index, :show, :edit, :update
  action_item :import_listings, only: :show do
    link_to 'Force listings import', import_listings_admin_panel_fareharbor_company_path(resource),  method: :put
  end

  member_action :import_listings, method: :put do
    FareharborImportCompanyListingsJob.perform_later(@current_community.id, resource.id)
    redirect_to resource_path, notice: "Scheduled listings import!"
  end

  controller do
    def permitted_params
      params.permit :utf8, :_method, :authenticity_token, :commit, :id, :locale,
        fareharbor_company: [
          :active,
          :new_listings_open,
          :category_id,
        ]
    end
  end

  filter :name
  filter :shortname
  filter :address_city, label: 'City'
  filter :address_province, label: 'State'
  filter :address_country, label: 'Country',
    as: :select,
    collection: proc { FareharborCompany.order(:address_country).distinct.pluck(:address_country) }
  filter :currency,
    as: :select,
    collection: proc { ['usd', 'eur', 'gbp'] }
  filter :address_postal_code, label: 'Postal Code'
  filter :created_at
  filter :updated_at

  scope :active

  action_item :force_resync, only: :index do
    link_to 'Force FareHarbor Resync', force_resync_admin_panel_fareharbor_companies_path, 
            method: :post, 
            data: { 
              confirm: 'This will trigger a full FareHarbor import for all active companies. Are you sure?',
              disable_with: 'Resyncing...'
            },
            class: 'btn btn-warning',
            style: 'margin-bottom: 10px;'
  end

  collection_action :force_resync, method: :post do
    FareharborImportListingsJob.perform_later(@current_community.id)
    
    redirect_to admin_panel_fareharbor_companies_path, 
                notice: "FareHarbor resync has been queued! Check the logs below for progress."
  end

  index do
    panel 'Latest FareHarbor Logs' do
      log_file_path = Rails.root.join('log', 'fareharbor_updater.log')
      
      if File.exist?(log_file_path)
        log_content = `tail -n 30 "#{log_file_path}"`
        
        div class: 'log-container', style: 'background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px; padding: 15px; margin-bottom: 20px;' do
          h4 'Recent FareHarbor Import Activity', style: 'margin-top: 0; color: #495057;'
          
          textarea readonly: true, style: 'width: 100%; height: 150px; background-color: #000; color: #00ff00; border: 1px solid #333; border-radius: 3px; font-family: monospace; font-size: 11px; padding: 10px; resize: none; outline: none;' do
            log_content.present? ? log_content : 'No recent log entries found.'
          end
          
          div style: 'margin-top: 10px; font-size: 12px; color: #6c757d;' do
            "Last updated: #{File.mtime(log_file_path).strftime('%Y-%m-%d %H:%M:%S')} | "
            link_to 'Refresh logs', '#', onclick: 'location.reload(); return false;', style: 'color: #007bff;'
          end
        end
      else
        div class: 'alert alert-info', style: 'padding: 15px; margin-bottom: 20px; border: 1px solid #bee5eb; background-color: #d1ecf1; border-radius: 4px;' do
          'No FareHarbor log file found. Logs will appear here after the first import runs.'
        end
      end
    end

    selectable_column
    id_column
    column :name
    column :shortname
    column 'City', :address_city
    column 'State', :address_province
    column 'Country', :address_country
    column :active
    column :new_listings_open
    column :category do |company|
      company.category.display_name(:en)
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :shortname
      row :active
      row :new_listings_open
      row :category do |company|
        company.category.display_name(:en)
      end
      row :person do |company|
        if company.person
          link_to company.person.username, admin_panel_person_path(company.person.username)
        end
      end
      row :person_in_site do |company|
        if company.person
          link_to company.person.display_name, "/en/#{company.person.username}"
        end
      end
      row :listings do |company|
        if company.person
          options = {
            utf8: '✓',
            'q[author_id_eq]': company.person.id,
            commit: 'Filter',
            locale: :en,
            order: 'id_desc',
          }
          link_to 'Listings', admin_panel_listings_path(options)
        end
      end
      row :currency
      row :affiliated_since
      row :summary
      row :about
      row :booking_notes
      row :faq
      row :intro
      row :address_street
      row :address_city
      row :address_province
      row :address_country
      row :address_postal_code
      row :billing_address_street
      row :billing_address_city
      row :billing_address_province
      row :billing_address_country
      row :billing_address_postal_code
      row :primary_location
      row :primary_location_heading
      row :url
      row :facebook_url
      row :instagram_url
      row :tripadvisor_url
      row :twitter_url
      row :yelp_url
      row :youtube_url
      row :pinterest_url
      row :health_and_safety_policy
      row :open_hours

      row :created_at
      row :updated_at
    end
    #active_admin_comments
  end

  form title: 'A custom title' do |f|
    inputs 'Details' do
      li "Name <strong>#{f.object.name}</strong>".html_safe
      li "Shortname <strong>#{f.object.shortname}</strong>".html_safe
      input :active
      input :new_listings_open
      input :category
    end
    panel 'Note' do
      "These settings will affect new imported/updated listings."
    end
    actions
  end
end
