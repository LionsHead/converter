require 'swagger_helper'
RSpec.describe 'Api::V1::Documents', type: :request, swagger_doc: 'v1/swagger.yaml' do
  path '/api/v1/documents' do
    post 'Upload new document' do
      tags 'Documents'
      consumes 'multipart/form-data'
      produces 'application/json'
      description 'Uploads an SVG file and convert.'
      parameter name: :svg_file, in: :formData, schema: {
        type: :object,
        properties: {
          svg_file: { type: :file, description: 'SVG file to upload' },
        },
        required: %w[svg_file]
      }

      response 201, 'created' do
        schema type: :object,
          properties: {
            id: { type: :integer, example: 1 },
            original_file_name: { type: :string, example: 'test.svg' },
            status: { type: :string, example: 'pending', enum: %w[pending processing completed failed] },
          },
          required: %w[id original_file_name status]

        let(:svg_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.svg'), 'image/svg+xml') }

        run_test! do
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['id']).to be_present
        end
      end
      response 422, 'unprocessable entity' do
        schema type: :object,
               properties: { errors: { type: :array, items: { type: :string } } },
               example: { errors: ['Svg file can\'t be blank'] }

        let(:svg_file) { nil }

        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  path '/api/v1/documents/{id}' do
    get 'Check document status' do
      tags 'Documents'
      produces 'application/json'
      description 'Retrieves the status of a document by ID'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Ducument ID'

      response 200, 'successful' do
        schema type: :object,
          properties: {
            id: { type: :integer, example: 1 },
            original_file_name: { type: :string, example: 'test.svg' },
            pdf_file_url: { type: :string, example: 'url/to/generated_test.pdf', nullable: true },
            status: { type: :string, example: 'pending', enum: %w[pending processing completed failed] },
          },
          required: %w[id original_file_name status]

        let(:document) { create(:document, :with_svg_file) }
        let(:id) { document.id }

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['id']).to eq(id)
        end
      end
    end
  end
end
