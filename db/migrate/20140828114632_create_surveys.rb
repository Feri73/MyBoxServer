class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
    	t.text :subject
    	t.datetime :expire_date

    	t.integer :user_id
    	t.integer :organization_id

      t.timestamps
    end
  end
end
