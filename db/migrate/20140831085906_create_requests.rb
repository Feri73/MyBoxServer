class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
    	t.integer :user_id
    	t.integer :organization_id
    	t.integer :answer
      t.timestamps
    end
  end
end
