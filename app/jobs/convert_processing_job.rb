class ConvertProcessingJob < ApplicationJob
  queue_as :default

  def perform(document_id, check_with_ai:)
    document = Document.find(document_id)

    ConvertProcessor.call(document, with_ai: check_with_ai)
  rescue StandardError => e
    logger.error "ConvertProcessingJob failed for document #{document_id}: #{e.message}"
    logger.error e.backtrace.join("\n")

    document&.fail! unless document.failed?
  end
end
