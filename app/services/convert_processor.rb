class ConvertProcessor < BaseService
  def initialize(document)
    @document = document
  end

  def call
    validate_document!
    generate_pdf
    attach_pdf_to_document

    success(@document)
  rescue StandardError => e
    error "ConvertProcessor failed: #{e.message}"
    error "Backtrace: #{e.backtrace.join("\n")}"
    @document.fail! unless @document.failed? || @document.validation_failed?

    failure(error: e.message)
  end

  private

  attr_reader :document, :svg_content, :pdf_content

  def validate_document!
    info "ConvertProcessor: Validating document #{document.id}"

    @svg_content = document.svg_content
    document.start_validation!

    if svg_content.blank?
      document.validation_fail!
      fail!(error: "SVG content is blank")
    end

    validation_result = SvgValidator.call(svg_content)

    unless validation_result.success?
      document.validation_fail!
      fail!(error: "SVG validation failed: #{validation_result.error}")
    end

    document.validation_succeed!
  end

  def generate_pdf
    info "ConvertProcessor: Starting PDF generation"

    custom_config = {
      page_config: custom_page_config,
      watermark_config: {
        text: "Endurance"
      }
    }

    pdf_result = PdfGenerator.call(svg_content, **custom_config)

    fail!(error: "PDF generation failed") if pdf_result.failure?

    @pdf_content = pdf_result.data
  end

  def attach_pdf_to_document
    fail!(error: "Empty PDF content") if @pdf_content.blank?

    filename = generate_pdf_filename

    document.generated_file_name = filename
    document.pdf_file.attach(
      io: StringIO.new(@pdf_content),
      filename: filename,
      content_type: "application/pdf"
    )

    document.complete!
  end

  def generate_pdf_filename
    base_name = File.basename(document.original_file_name, File.extname(document.original_file_name))
    "#{base_name}_#{Time.current.to_i}.pdf"
  end

  def custom_page_config
    {
      margin: {
        top: "50mm",
        right: "20mm",
        bottom: "50mm",
        left: "20mm"
      }
    }
  end

  def fail!(error:)
    error "ConvertProcessor failed: #{error}"
    raise StandardError, error
  end
end
