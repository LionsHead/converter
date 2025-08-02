class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :original_file_name
      t.string :generated_file_name
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
