class WatermarkPattern
  def initialize(text, config)
    @text = text
    @config = config
  end

  def to_svg
    dimensions = @config.pattern_dimensions

    <<~SVG
      <svg width="#{dimensions[:width]}" height="#{dimensions[:height]}"
           viewBox="0 0 #{dimensions[:width]} #{dimensions[:height]}" xmlns="http://www.w3.org/2000/svg">
          <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="28" font-weight="900"
                fill="rgba(0,0,0,#{@config.opacity})" text-anchor="middle" dominant-baseline="middle"
                transform="rotate(#{@config.rotation} #{dimensions[:width]/2} #{dimensions[:height]/2})">
              #{ERB::Util.html_escape(@text)}
          </text>
      </svg>
    SVG
  end

  def to_data_uri
    base64_svg = Base64.strict_encode64(to_svg)
    "data:image/svg+xml;base64,#{base64_svg}"
  end
end
