#
# Fareharbor requires a request path ending with a slash
# "companies/" where ending "/" is important
#
module OwnoutdoorsSpykePath
  def path
    validate_required_variables!
    uri_template.expand(@params).to_s
  end
end

::Spyke::Path.prepend(OwnoutdoorsSpykePath)
