class Admin::RedprofileUsersController < Admin::AdminBaseController
  def create
    @person = Person.new({
        username: params[:username],
        community_id: @current_community.id,
        given_name: params[:given_name],
        family_name: params[:family_name],
        description: params[:description],
        locale: I18n.locale,
        password: params[:password],
        is_vendor: params[:is_vendor],
        website_url: params[:website_url]
      })
    @person.skip_phone_validation = true
    email_address = params[:email].downcase.strip
    allowed_and_available = @current_community.email_allowed?(email_address) && Email.email_available?(email_address, @current_community.id)
    unless allowed_and_available
      flash[:error] = "The email #{email_address} is already in use"
      redirect_to admin_community_community_memberships_path(@current_community)
      return
    end

    username_exists = Person.where(community_id: @current_community.id, username: params[:username]).exists?
    if username_exists
      flash[:error] = "The email #{email_address} is already in use"
      redirect_to admin_community_community_memberships_path(@current_community)
      return
    end

    @email = Email.new(:person => @person, :address => params[:email].downcase.strip, :send_notifications => true, community_id: @current_community.id)
    @person.emails << @email
    @person.inherit_settings_from(@current_community)
    @person.set_default_preferences
    @person.save!
    @membership = CommunityMembership.new(:person => @person, :community => @current_community, :consent => @current_community.consent, status: 'pending_email_confirmation')
    @membership.save!
    if @person.is_vendor
      @person.image = File.new(Rails.root+"app/assets/images/gray_shop_logo.png")
      @person.save
    end
    redirect_to admin_community_community_memberships_path(@current_community)
  end

  def import
    @csv_importer = CSVImporter.new(@current_community, params[:file])
    @csv_importer.process
  end

  def reference_package
    @csv_importer = CSVImporter.new(@current_community, nil)
    send_data @csv_importer.reference_package.to_stream.read, 
      filename: 'reference-data.xlsx', 
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
      disposition: 'attachment'
  end
end
