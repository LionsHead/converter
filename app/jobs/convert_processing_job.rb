class ConvertProcessingJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)

    ConvertProcessor.call(document)
  rescue StandardError => e
    logger.error "ConvertProcessingJob failed for document #{document_id}: #{e.message}"
    logger.error e.backtrace.join("\n")

    document&.fail! unless document.failed?
  end
end
