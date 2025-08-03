require 'rails_helper'

RSpec.describe PdfGenerator do
  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:watermark_text) { 'Sample Watermark' }
  let(:html_content) { '<html><body>test</body></html>' }
  let(:pdf_content) { 'PDF binary content' }

  describe '.call' do
    subject(:result) { described_class.call(svg_content, watermark_text: watermark_text) }

    context 'when PDF generation succeeds' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it_behaves_like 'successful service result'

      it { expect(result.data).to eq(pdf_content) }

      it 'builds HTML from SVG and watermark' do
        expect(HtmlBuilder).to receive(:call).with(svg_content, watermark_text)
        result
      end
    end

    context 'when HTML building fails' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(failure_result("HTML build error"))
      end

      it_behaves_like 'failed service result', "html content is nil"
    end

    context 'when HTML content is blank' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(''))
      end

      it_behaves_like 'failed service result', "html content is nil"
    end

    context 'when PDF generation returns nil' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(nil)
      end

      it_behaves_like 'failed service result', "pdf content is nil"
    end

    context 'when PDF generation returns empty content' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return('')
      end

      it_behaves_like 'failed service result', "pdf content is nil"
    end

    context 'when exception occurs during generation' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_raise(StandardError, "Chrome crashed")
      end

      it 'handles errors gracefully' do
        expect(result).to be_nil
      end
    end

    context 'without watermark text' do
      subject(:result) { described_class.call(svg_content) }

      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it_behaves_like 'successful service result'

      it 'passes empty watermark to HTML builder' do
        expect(HtmlBuilder).to receive(:call).with(svg_content, "")
        result
      end
    end
  end

  describe '#call instance method' do
    subject(:generator) { described_class.new(svg_content, watermark_text: watermark_text) }

    let(:result) { generator.call }

    context 'when generation succeeds' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it { expect(result).to be_successful_service_result }

      it { expect(result.data).to eq(pdf_content) }
    end

    context 'when generation fails' do
      before do
        allow(HtmlBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(nil)
      end

      it { expect(result).to be_failed_service_result("pdf content is nil") }
    end
  end

  describe 'initialization' do
    context 'with watermark text' do
      subject { described_class.new(svg_content, watermark_text: watermark_text) }

      it { is_expected.to be_a(described_class) }
      it { is_expected.to respond_to(:call) }
    end

    context 'without watermark text' do
      subject { described_class.new(svg_content) }

      it { is_expected.to be_a(described_class) }
      it { is_expected.to respond_to(:call) }
    end
  end
end
