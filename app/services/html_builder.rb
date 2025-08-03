class HtmlBuilder < BaseService
    def initialize(svg_content, watermark_text)
      @svg_content = svg_content
      @watermark_text = watermark_text
    end

    def call
      html_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>SVG to PDF converted</title>
          <style>
            #{css_styles}
          </style>
        </head>
        <body>
          <div class="page">
            <div class="content">
              #{@svg_content}
            </div>
            <div class="watermark">#{@watermark_text}</div>
            #{crop_marks}
          </div>
        </body>
        </html>
      HTML

      success(html_content)
    end

    private

    def css_styles
      <<~CSS
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: Arial, sans-serif;
          background: white;
        }

        .page {
          position: relative;
          width: 100%;
          height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }

        .content {
          max-width: 80%;
          max-height: 80%;
          display: flex;
          justify-content: center;
          align-items: center;
        }

        .content svg {
          max-width: 100%;
          max-height: 100%;
          width: auto;
          height: auto;
        }

        @media print {
          body { margin: 0; }
          .page { margin: 0; }
        }
      CSS
    end

    def crop_marks
      <<~HTML
        <div class="crop-mark top-left"></div>
        <div class="crop-mark top-right"></div>
        <div class="crop-mark bottom-left"></div>
        <div class="crop-mark bottom-right"></div>
      HTML
    end
end
