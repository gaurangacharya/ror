class PopulateConfirmedFlag < ActiveRecord::Migration[5.1]
  class Person < ApplicationRecord
    has_many :emails
    self.primary_key = "id"
  end
  def up
    Person.all.each do |person|
      if person.emails.where('confirmed_at IS NOT NULL').count > 0
        person.is_confirmed = 1
        person.save
      end
    end
  end
end
