class ConvertProcessor < BaseService
  def initialize(document)
    @document = document
  end

  def call
    prepare_svg_content
    validate_document!
    generate_pdf
    attach_pdf_to_document
    complete_processing

    success(@document)
  rescue StandardError => e
    @document.fail! unless @document.failed? || @document.validation_failed?

    failure(error: e.message)
  end

  private

  attr_reader :document, :svg_content, :pdf_content

  def prepare_svg_content
    @svg_content = document.svg_content
  end

  def validate_document!
    document.start_validation!

    validation_result = SvgValidator.call(svg_content)

    unless validation_result.success?
      document.validation_fail!
      fail!(error: "SVG validation failed: #{validation_result.error}")
    end

    document.validation_succeed!
    @svg_content = validation_result.data
  end

  def generate_pdf
    pdf_result = PdfGenerator.call(@svg_content, watermark_text: "Endurance for MaxaTech")

    fail!(error: "PDF generation failed") if pdf_result.failure?

    @pdf_content = pdf_result.data
  end

  def attach_pdf_to_document
    fail!(error: "Empty PDF content") if @pdf_content.blank?

    filename = generate_pdf_filename

    document.pdf_file.attach(
      io: StringIO.new(@pdf_content),
      filename: filename,
      content_type: "application/pdf"
    )

    document.update!(generated_file_name: filename)
  end

  def complete_processing
    document.complete!
  end

  def generate_pdf_filename
    base_name = File.basename(document.original_file_name, File.extname(document.original_file_name))
    "#{base_name}_#{Time.current.to_i}.pdf"
  end

  def fail!(error:)
    error "ConvertProcessor failed: #{error}"
    raise StandardError, error
  end
end
