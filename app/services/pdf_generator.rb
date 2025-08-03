class PdfGenerator < BaseService
  def initialize(svg_content, watermark_text: "")
    @svg_content = svg_content
    @watermark_text = watermark_text
  end

  def call
    info "PdfGenerator: Starting generation"

    html_content = build_html_content
    return failure(error: "PDF generation failed: html content is nil") if html_content.blank?

    pdf_content = generate_pdf_from html_content

    info "PdfGenerator: pdf_content size: #{pdf_content.size} bytes" if pdf_content
    return failure(error: "PDF generation failed: pdf content is nil") if pdf_content.blank?

    success(pdf_content)
  rescue StandardError => e
    error "PDF generation failed: #{e.message}"
    error "Backtrace: #{e.backtrace.join("\n")}"
    nil
  end

  private

  attr_reader :svg_content, :watermark_text

  def build_html_content
    result = HtmlBuilder.call(svg_content, watermark_text)
    return nil if result.failure?

    result.data
  end

  def generate_pdf_from(html_content)
    info "PdfGenerator: Starting generation from HTML content"

    Tempfile.create(["pdf_generation", ".pdf"]) do |pdf_file|
      browser = build_headless_browser
      browser.go_to("data:text/html;charset=utf-8,#{CGI.escape(html_content)}")

      browser.network.wait_for_idle(duration: 1)

      browser.pdf(
        path: pdf_file.path,
        format: :A4,
        margin: {
          top: "30mm",
          right: "20mm",
          bottom: "30mm",
          left: "20mm"
        },
        print_background: true,
        prefer_css_page_size: false
      )

      if File.exist?(pdf_file.path) && File.size(pdf_file.path) > 0
        return File.read(pdf_file.path, mode: "rb")
      else
        raise "PDF file is empty or doesn't exist"
      end
    end
  end

  def build_headless_browser
    config = {
      ws_url: ENV.fetch("REMOTE_CHROME_WS_URL", "ws://chrome:3000"),
      timeout: 30,
      headless: true,
      browser_options: browser_options
    }

    Ferrum::Browser.new(config)
  end

  def browser_options
    {
      "args" => [
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--disable-software-rasterizer",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding"
      ]
    }
  end

  # local debug - remove this method if not needed
  def find_local_chrome_path
    paths = [
      "/usr/bin/chromium",
      "/usr/bin/chromium-browser",
      "/usr/bin/google-chrome",
      "/usr/bin/google-chrome-stable",
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ]

    paths.find { |path| File.exist?(path) }
  end
end
