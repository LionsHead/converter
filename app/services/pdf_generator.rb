class PdfGenerator < BaseService
  def initialize(svg_content, page_config: {}, watermark_config: {})
    @svg_content = svg_content
    @page_config = page_config
    @watermark_config = watermark_config
  end

  def call
    info "PdfGenerator: Starting generation"

    html_content = build_html_content

    return failure(error: "PDF generation failed: html content is nil") if html_content.blank?

    pdf_content = generate_pdf_from html_content

    return failure(error: "PDF generation failed: pdf content is nil") if pdf_content.blank?

    success(pdf_content)
  rescue StandardError => e
    error "PDF generation failed: #{e.message}"
    error "Backtrace: #{e.backtrace.join("\n")}"

    failure(error: e.message)
  end

  private

  attr_reader :svg_content, :page_config, :watermark_config

  def build_html_content
    result = Pdf::HtmlBuilder.call(svg_content, watermark_config: watermark_config)
    return nil if result.failure?

    result.data
  end

  def generate_pdf_from(html_content)
    info "PdfGenerator: Starting generation from HTML content"

    Tempfile.create(["pdf_generation", ".pdf"], encoding: "binary") do |pdf_file|
      encoded_html = Base64.strict_encode64(html_content)
      data_uri = "data:text/html;base64,#{encoded_html}"

      browser = build_headless_browser
      browser.go_to(data_uri)
      browser.network.wait_for_idle(duration: 1)

      browser.pdf(
        path: pdf_file.path,
        format: :A4,
        margin: pdf_margins,
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

  def pdf_margins
    default_margins = {
      top: "20mm",
      right: "20mm",
      bottom: "20mm",
      left: "20mm"
    }

    default_margins.merge(page_config.fetch(:margin, {}))
  end

  def build_headless_browser
    config = {
      timeout: 30,
      headless: true,
      browser_options: browser_options
    }

    if ENV["REMOTE_CHROME_WS_URL"].present?
      config[:ws_url] = ENV.fetch("REMOTE_CHROME_WS_URL", "ws://chrome:3000")
    else
      config[:path] = find_local_chrome_path
    end

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
