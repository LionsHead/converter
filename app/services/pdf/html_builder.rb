module Pdf
  class HtmlBuilder < BaseService
    DEFAULT_CONFIG = {
      text: "Maxa Watermark",
      size: { width: 250, height: 250 },
      font_size: 48,
      opacity: 0.1,
      rotation: -40,
      repeat_size: { width: 250, height: 150 }
    }.freeze

    def initialize(svg_content, watermark_config: {})
      @svg_content = svg_content
      @watermark_config = DEFAULT_CONFIG.deep_merge(watermark_config)
    end

    def call
      return failure(error: "SVG content is blank") if svg_content.blank?
      return failure(error: "Watermark text is blank") if watermark_text.blank?

      html_content = build_content(svg_content)

      success(html_content)
    rescue StandardError => e
      error "HTML generation failed: #{e.message}"

      failure(error: e.message)
    end

    private

    attr_reader :svg_content, :watermark_config

    def watermark_text
      watermark_config[:text]
    end

    def build_watermark_pattern
      escaped_watermark_text = ERB::Util.html_escape(watermark_config[:text])

      <<~SVG_PATT
        <svg width="#{watermark_config[:size][:width]}" height="#{watermark_config[:size][:height]}" viewBox="0 0 #{watermark_config[:size][:width]} #{watermark_config[:size][:height]}" xmlns="http://www.w3.org/2000/svg">
            <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="#{watermark_config[:font_size]}" font-weight="900"
                  fill="rgba(0,0,0,#{watermark_config[:opacity]})" text-anchor="middle" dominant-baseline="middle"
                  transform="rotate(#{watermark_config[:rotation]} #{watermark_config[:size][:width]/2} #{watermark_config[:size][:height]/2})">
                #{escaped_watermark_text}
            </text>
        </svg>
      SVG_PATT
    end

    def build_content(svg_content)
      base64_svg = Base64.strict_encode64(build_watermark_pattern)
      data_uri = "data:image/svg+xml;base64,#{base64_svg}"

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Converted SVG</title>
          <style>
            #{css_styles(data_uri)}
          </style>
        </head>
        <body>
          <div class="page-wrapper">
            <div class="page-container">
              <div class="page-content">
                <div class="header-section">
                  <h1 class="main-title">Generated PDF from SVG</h1>
                  <p class="description">
                    Demo of SVG to PDF conversion with watermarking and styling.
                  </p>
                </div>

                <div class="svg-wrapper">
                  <div class="content">
                    #{svg_content}
                  </div>
                </div>

                <div class="footer-section">
                  <p class="footer-text">
                    For Maxa Designs. © #{Time.now.year}
                  </p>
                </div>
              </div>
            </div>

            <div class="watermark-overlay"></div>
          </div>
        </body>
        </html>
      HTML
    end

    def css_styles(data_uri)
      <<~CSS
        @page {
          size: A4;
          margin: 0;
        }

        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        html, body {
          width: 210mm;
          height: 297mm;
          position: relative;
          font-family: 'Arial', sans-serif;
          background-color: white;
          overflow: hidden;
        }

        .page-wrapper {
          position: relative;
          width: 100%;
          height: 100%;
        }

        .page-container {
          position: relative;
          width: 100%;
          height: 100%;
          padding: 20mm;
          z-index: 1;
        }

        .page-content {
          height: 100%;
          display: flex;
          flex-direction: column;
          justify-content: space-between;
          align-items: center;
        }

        .header-section {
          width: 100%;
          margin-bottom: 20px;
        }

        .main-title {
          text-align: center;
          font-size: 28px;
          color: #333;
          margin-bottom: 15px;
        }

        .description {
          text-align: center;
          font-size: 14px;
          color: #666;
          max-width: 80%;
          margin: 0 auto 20px;
        }

        .svg-wrapper {
          display: flex;
          justify-content: center;
          align-items: center;
          flex-grow: 1;
          width: 100%;
          overflow: hidden;
        }

        .content svg {
          max-width: 100%;
          max-height: 100%;
          height: auto;
          width: auto;
          object-fit: contain;
          display: block;
        }

        .footer-section {
          width: 100%;
          margin-top: 20px;
        }

        .footer-text {
          text-align: center;
          font-size: 12px;
          color: #999;
        }

        .watermark-overlay {
          position: absolute;
          top: 0;
          left: 0;
          width: 210mm;
          height: 297mm;
          pointer-events: none;
          z-index: 9999;
          background-image: url('#{data_uri}');
          background-repeat: repeat;
          background-position: 0 0;
          background-size: #{watermark_config[:repeat_size][:width]}px #{watermark_config[:repeat_size][:height]}px;
        }

        @media print {
          .watermark-overlay {
            print-color-adjust: exact;
            -webkit-print-color-adjust: exact;
          }
        }
      CSS
    end
  end
end
