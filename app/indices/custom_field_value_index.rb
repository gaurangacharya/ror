if APP_CONFIG.use_thinking_sphinx_indexing.to_s.casecmp("true") == 0
  ThinkingSphinx::Index.define :custom_field_value, :with => :real_time do

    #Thinking Sphinx will automatically add the SQL command SET NAMES utf8 as
    # part of the indexing process if the database connection settings have
    # encoding set to utf8. This is default in Rails but with Heroku, we need to
    # be explicit.
    set_property :utf8? => true

    # attributes
    has listing_id, type: :integer
    has custom_field_id, type: :integer
    has numeric_value, type: :float

  end
end
