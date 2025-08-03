module Api
  module V1
    class DocumentsController < Api::ApplicationController
      def create
        document = Document.new
        if params[:svg_file].present?
         document.svg_file.attach(params[:svg_file])
          document.original_file_name = params[:svg_file].original_filename
        end

        if document.save
          ConvertProcessingJob.perform_later(document.id)

          render json: UploadedDocumentSerializer.new(document), status: :created
        else
          render json: { errors: document.errors.full_messages }, status: :unprocessable_content
        end
      end

      def show
        document = Document.find(params[:id])
        render json: UploadedDocumentSerializer.new(document)
      end
    end
  end
end
