class Admin::PeopleController < Admin::AdminBaseController
  def autocomplete_person_name
    term = params[:term]
    people = resource_scope
      .where(<<-SQL_QUERY.strip_heredoc, s: "%#{term}%")
        LOWER(people.username) LIKE LOWER(:s) OR
        LOWER(people.given_name) LIKE LOWER(:s) OR
        LOWER(people.family_name) LIKE LOWER(:s) OR
        LOWER(people.display_name) LIKE LOWER(:s) OR
        LOWER(emails.address) LIKE LOWER(:s)
      SQL_QUERY
      .order(:username)
      .limit(10)
    result = people.map do |person|
      label = "#{person.username} (#{person.emails.first&.address}) #{person.display_name}"
      {
        id: person.id,
        label: label,
        value: person.username,
      }
    end
    render :json => result
  end

  private

  def resource_scope
    Person.joins(:community_memberships, :emails).where(community_memberships: { community_id: @current_community.id })
  end
end
