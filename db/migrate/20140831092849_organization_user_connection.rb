class OrganizationUserConnection < ActiveRecord::Migration
  def change
  	create_table :organizations_users , :id => false do |t|
    	t.integer :user_id
    	t.integer :organization_id

      t.timestamps
    end
  end
end
