class SvgValidator < BaseService
  def initialize(svg_content)
    @svg_content = svg_content
  end

  def call
    info "SvgValidator: Starting SVG validation"

    return failure(error: "Empty SVG content") if svg_content.blank?

    errors = []

    errors << "Invalid XML structure" unless valid_xml?

    if errors.any?
      failure(error: errors.join(", "), data: { errors: errors })
    else
      success
    end
  end

  private

  attr_reader :svg_content

  def valid_xml?
    Nokogiri::XML(svg_content) { |config| config.strict }
    true
  rescue Nokogiri::XML::SyntaxError
    false
  end
end
