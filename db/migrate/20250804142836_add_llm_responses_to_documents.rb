class AddLlmResponsesToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :issues_found, :json, default: [], null: false
    add_column :documents, :warnings, :json, default: [], null: false
  end
end
