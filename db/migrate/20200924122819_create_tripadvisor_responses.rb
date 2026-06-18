class CreateTripadvisorResponses < ActiveRecord::Migration[5.1]
  def change
    create_table :tripadvisor_responses do |t|
      t.string :location_id
      t.mediumtext :body

      t.timestamps
    end
  end
end
