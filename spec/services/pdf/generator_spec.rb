require 'rails_helper'

RSpec.describe Pdf::Generator do
  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:page_config) { { margin: { top: '10mm' } } }
  let(:watermark_config) { { text: 'Sample Watermark', opacity: 0.5 } }
  let(:html_content) { '<html><body>test</body></html>' }
  let(:pdf_content) { 'PDF binary content' }

  describe '.call' do
    subject(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

    context 'when PDF generation succeeds' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it { should be_successful_service_result }
      it { expect(result.data).to eq(pdf_content) }

      it 'builds HTML with correct parameters' do
        result
        expect(Pdf::TemplateBuilder).to have_received(:call).with(svg_content, watermark_config: watermark_config)
      end
    end

    context 'when HTML building fails' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(failure_result("HTML build error"))
      end

      it { should be_failed_service_result }
      it { expect(result.error).to match(/html content is nil/) }
    end

    context 'when HTML content is blank' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(''))
      end

      it { should be_failed_service_result }
      it { expect(result.error).to match(/html content is nil/) }
    end

    context 'when PDF generation returns nil' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(nil)
      end

      it { should be_failed_service_result }
      it { expect(result.error).to match(/pdf content is nil/) }
    end

    context 'when PDF generation returns empty content' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return('')
      end

      it { should be_failed_service_result }
      it { expect(result.error).to match(/pdf content is nil/) }
    end

    context 'when exception occurs during generation' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_raise(StandardError, "Chrome crashed")
      end

      it { should be_failed_service_result }
      it { expect(result.error).to eq("Chrome crashed") }
    end

    context 'with minimal parameters' do
      subject(:result) { described_class.call(svg_content) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it { should be_successful_service_result }

      it 'passes empty configs to HTML builder' do
        result
        expect(Pdf::TemplateBuilder).to have_received(:call).with(svg_content, watermark_config: {})
      end
    end
  end

  describe '#call instance method' do
    subject(:generator) { described_class.new(svg_content, page_config: page_config, watermark_config: watermark_config) }
    let(:result) { generator.call }

    context 'when generation succeeds' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it { expect(result).to be_successful_service_result }
      it { expect(result.data).to eq(pdf_content) }
    end

    context 'when HTML building fails' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(failure_result("HTML error"))
      end

      it { expect(result).to be_failed_service_result }
      it { expect(result.error).to match(/html content is nil/) }
    end

    context 'when PDF generation fails' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(nil)
      end

      it { expect(result).to be_failed_service_result }
      it { expect(result.error).to match(/pdf content is nil/) }
    end

    context 'when exception is raised' do
      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_raise(StandardError, "PDF error")
      end

      it { expect(result).to be_failed_service_result }
      it { expect(result.error).to eq("PDF error") }
    end
  end

  describe 'initialization' do
    context 'with all parameters' do
      subject { described_class.new(svg_content, page_config: page_config, watermark_config: watermark_config) }

      it { should be_a(described_class) }
      it { should respond_to(:call) }
    end

    context 'with minimal parameters' do
      subject { described_class.new(svg_content) }

      it { should be_a(described_class) }
      it { should respond_to(:call) }
    end
  end
end
