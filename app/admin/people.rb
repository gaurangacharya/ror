ActiveAdmin.register(Person) do
  actions :index, :show
  action_item :import_fareharbor_listings, only: :show do
    if resource.fareharbor_company
      link_to 'Force Fareharbor listings import', import_fareharbor_listings_admin_panel_person_path(resource),  method: :put
    end
  end

  member_action :import_fareharbor_listings, method: :put do
    @person = Person.find_by(username: params[:id])
    FareharborImportCompanyListingsJob.perform_later(@current_community.id, resource.fareharbor_company.id)
    redirect_to resource_path, notice: "Scheduled Fareharbor listings import!"
  end

  controller do
    def show
      @person = Person.find_by(username: params[:id])
    end
  end

  scope :fareharbor

  filter :username
  filter :given_name
  filter :family_name
  filter :display_name
  filter :created_at

  index do
    selectable_column
    column :username
    column :given_name
    column :family_name
    column :display_name

    actions
  end

  show do
    attributes_table do
      row :person_in_site do |person|
        link_to person.display_name, "/en/#{person.username}"
      end
      row :username
      row :listings do |person|
        options = {
          utf8: '✓',
          'q[author_id_eq]': person.id,
          commit: 'Filter',
          locale: :en,
          order: 'id_desc',
        }
        link_to 'Listings', admin_panel_listings_path(options)
      end
      row :fareharbor_company do |person|
        if person.fareharbor_company
          link_to 'Fareharbor company', admin_panel_fareharbor_company_path(person.fareharbor_company)
        end
      end
      row :given_name
      row :family_name
      row :display_name
      row :phone_number
      row :description
      row :website_url
    end
    panel "Fareharbor" do
      table_for person.person_fareharbors do
        column :fareharbor_shortname
        column :fareharbor_items
        column :updated
        column :failed
        column :deleted
        column :start_at
        column :end_at
      end
    end
  end
end
