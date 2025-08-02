class UploadedDocumentSerializer
  include Alba::Resource

  attributes :id, :original_file_name, :status

  attribute :pdf_file_url do |resource|
    resource.pdf_file.url if resource.pdf_file.attached?
  end
end
