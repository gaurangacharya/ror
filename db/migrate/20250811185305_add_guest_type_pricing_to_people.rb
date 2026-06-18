class AddGuestTypePricingToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :guest_type_pricing_enabled, :boolean, default: false, null: false
    add_index :people, :guest_type_pricing_enabled
    
    # Enable guest type pricing for existing Ladera users for backwards compatibility
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE people 
          SET guest_type_pricing_enabled = true 
          WHERE id IN (
            SELECT person_id 
            FROM person_white_labels 
            WHERE design = 'ladera'
          )
        SQL
      end
      
      dir.down do
        # On rollback, disable guest type pricing for Ladera users
        # (they'll still work via legacy detection)
        execute <<-SQL
          UPDATE people 
          SET guest_type_pricing_enabled = false 
          WHERE id IN (
            SELECT person_id 
            FROM person_white_labels 
            WHERE design = 'ladera'
          )
        SQL
      end
    end
  end
end
