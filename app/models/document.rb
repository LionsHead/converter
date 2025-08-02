class Document < ApplicationRecord
  has_one_attached :svg_file
  has_one_attached :pdf_file

  validates :svg_file, :original_file_name, presence: true
end
