require 'rails_helper'

RSpec.describe Pdf::Generator do
  include_context 'service result helpers'

  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:page_config) { { margin: { top: '10mm' } } }
  let(:watermark_config) { { text: 'Sample Watermark', opacity: 0.5 } }
  let(:html_content) { '<html><body>test</body></html>' }
  let(:pdf_content) { 'PDF binary content' }

  describe '.call' do
    context 'when PDF generation succeeds' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it_behaves_like 'successful service result'

      it 'returns PDF content' do
        expect(result.data).to eq(pdf_content)
      end

      it 'builds HTML with correct parameters' do
        result
        expect(Pdf::TemplateBuilder).to have_received(:call).with(svg_content, watermark_config: watermark_config)
      end
    end

    context 'when HTML building fails' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(failure_result("HTML build error"))
      end

      it_behaves_like 'failed service result', 'html content is nil'
    end

    context 'when HTML content is blank' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(''))
      end

      it_behaves_like 'failed service result', 'html content is nil'
    end

    context 'when PDF generation returns nil' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(nil)
      end

      it_behaves_like 'failed service result', 'pdf content is nil'
    end

    context 'when PDF generation returns empty content' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return('')
      end

      it_behaves_like 'failed service result', 'pdf content is nil'
    end

    context 'when exception occurs during generation' do
      let(:result) { described_class.call(svg_content, page_config: page_config, watermark_config: watermark_config) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_raise(StandardError, "Chrome crashed")
      end

      it_behaves_like 'failed service result', 'Chrome crashed'
    end

    context 'with minimal parameters' do
      let(:result) { described_class.call(svg_content) }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow_any_instance_of(described_class).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it_behaves_like 'successful service result'

      it 'passes empty configs to HTML builder' do
        result
        expect(Pdf::TemplateBuilder).to have_received(:call).with(svg_content, watermark_config: {})
      end
    end
  end

  describe '#call instance method' do
    subject(:generator) { described_class.new(svg_content, page_config: page_config, watermark_config: watermark_config) }

    context 'when generation succeeds' do
      let(:result) { generator.call }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(pdf_content)
      end

      it_behaves_like 'successful service result'

      it 'returns PDF content' do
        expect(result.data).to eq(pdf_content)
      end
    end

    context 'when HTML building fails' do
      let(:result) { generator.call }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(failure_result("HTML error"))
      end

      it_behaves_like 'failed service result', 'html content is nil'
    end

    context 'when PDF generation fails' do
      let(:result) { generator.call }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_return(nil)
      end

      it_behaves_like 'failed service result', 'pdf content is nil'
    end

    context 'when exception is raised' do
      let(:result) { generator.call }

      before do
        allow(Pdf::TemplateBuilder).to receive(:call).and_return(success_result(html_content))
        allow(generator).to receive(:generate_pdf_from).and_raise(StandardError, "PDF error")
      end

      it_behaves_like 'failed service result', 'PDF error'
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
