class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
    	t.integer :suggestion_id
    	t.integer :survey_id
    	t.text :content

      t.timestamps
    end
  end
end
