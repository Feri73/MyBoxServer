class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
    	t.text :image_address
      t.string :title
    	t.text :content
    	t.integer :reg_type
    	t.text :reg_file_address

    	t.integer :user_id

      t.timestamps
    end
  end
end
