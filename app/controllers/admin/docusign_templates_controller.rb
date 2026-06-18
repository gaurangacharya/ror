class Admin::DocusignTemplatesController < Admin::AdminBaseController
  def index
    @documents = Document.by_community(@current_community.id).shared_templates.ordered
    @docusign_auth = DocusignAuthorization.where(community_id: @current_community.id).first_or_create
    @selected_left_navi_link = "docusign"
  end

  def create
    document = Document.create(
      person: @current_user,
      community: @current_community,
      document_role: 'template',
      person_role: 'admin',
      doc_type: params[:doc_type],
      docusign_id: params[:docusign_id],
      title: params[:title]
    )
    document.download_from_docusign
    redirect_to action: :index
  end

  def destroy
    document = Document.by_community(@current_community.id).shared_templates.find(params[:id])
    Listing.where(document_id: document.id).update_all(document_id: nil)
    document.destroy
    redirect_to action: :index
  end

end
