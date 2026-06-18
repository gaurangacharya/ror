class AdminPanel::AuthorsController < Admin::AdminBaseController
  def search
    q = Person.ransack(params[:q])
    people = q.result.includes(:emails)
    result = people.map do |person|
      {
        id: person.id,
        long_name: person.long_name,
      }
    end
    render :json => result
  end
end
