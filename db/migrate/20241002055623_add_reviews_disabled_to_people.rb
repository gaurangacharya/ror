class AddReviewsDisabledToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :reviews_disabled, :boolean, default: false
  end
end
