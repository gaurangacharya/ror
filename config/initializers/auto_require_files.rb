# Require files on startup
#
# Autoload path approach does not work for lib files without
# a class to load

# Fix for Ruby 3.2+ compatibility - define URI methods early
module URI
  def self.escape(url)
    URI::Parser.new.escape(url)
  end
  
  def self.unescape(url)
    URI::Parser.new.unescape(url)
  end
end

files_to_load = [
  "#{Rails.root}/app/utils/pattern_matching"
]

files_to_load.each { |file| require file }
