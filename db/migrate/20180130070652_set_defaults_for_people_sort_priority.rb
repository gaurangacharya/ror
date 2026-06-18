class SetDefaultsForPeopleSortPriority < ActiveRecord::Migration[5.1]
  class Person < ApplicationRecord
    self.primary_key = "id"
  end
  def up
    Person.all.each{|p| p.save }
  end
end
