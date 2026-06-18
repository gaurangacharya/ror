class CreatePersonWhiteLabels < ActiveRecord::Migration[5.1]
  def change
    create_table :person_white_labels do |t|
      t.string :person_id
      t.string :logo_file_name
      t.string :logo_content_type
      t.integer :logo_file_size
      t.datetime :logo_updated_at
      t.boolean :logo_processing
      t.string :wide_logo_file_name
      t.string :wide_logo_content_type
      t.integer :wide_logo_file_size
      t.datetime :wide_logo_updated_at
      t.boolean :wide_logo_processing
      t.string :custom_color1
      t.string :custom_color2
      t.string :slogan_color
      t.string :description_color

      t.timestamps
    end
    add_index :person_white_labels, :person_id
  end
end
