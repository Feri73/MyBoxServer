class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
    	t.text :content
    	
    	t.integer :user_id
    	t.integer :organization_id

      t.timestamps
    end
  end
end
