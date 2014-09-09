class CreateQuestionsUsers < ActiveRecord::Migration
  def change
    create_table :questions_users do |t|
		t.integer :question_id
    	t.integer :user_id
    	t.integer :option_num
      t.timestamps
    end
  end
end
