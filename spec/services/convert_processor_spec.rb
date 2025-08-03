require 'rails_helper'

RSpec.describe ConvertProcessor do
  let(:document) { create(:document, :with_svg_file) }
  let(:svg_content) { '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle cx="50" cy="50" r="40"/></svg>' }
  let(:pdf_content) { 'fake pdf binary content' }

  subject(:result) { described_class.call(document) }

  before do
    allow(document).to receive(:svg_content).and_return(svg_content)
  end

  describe '#call' do
    context 'when conversion succeeds' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(PdfGenerator).to receive(:call).and_return(success_result(pdf_content))
        allow(document).to receive(:update!)
      end

      it_behaves_like 'successful service result'

      it { expect(result.data).to eq(document) }

      it 'processes document through complete workflow' do
        expect(document).to receive(:start_validation!).ordered
        expect(document).to receive(:validation_succeed!).ordered
        expect(document).to receive(:complete!).ordered

        result
      end

      it 'attaches PDF to document' do
        expect(document.pdf_file).to receive(:attach).with(
          io: be_a(StringIO),
          filename: end_with('.pdf'),
          content_type: 'application/pdf'
        )
        result
      end

      it 'updates document with generated filename' do
        expect(document).to receive(:update!).with(
          generated_file_name: end_with('.pdf')
        )
        result
      end
    end

    context 'when SVG validation fails' do
      let(:validation_error) { "Invalid SVG structure" }

      before do
        allow(SvgValidator).to receive(:call).and_return(failure_result(validation_error))
        allow(document).to receive(:validation_fail!)
      end

      it_behaves_like 'failed service result', "SVG validation failed"

      it 'transitions document to validation failed state' do
        expect(document).to receive(:start_validation!)
        expect(document).to receive(:validation_fail!)

        result
      end

      it { expect(PdfGenerator).not_to receive(:call); result }
    end

    context 'when PDF generation fails' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(PdfGenerator).to receive(:call).and_return(failure_result("Generation error"))
        allow(document).to receive(:fail!)
      end

      it_behaves_like 'failed service result', "PDF generation failed"

      it { expect(document).to receive(:fail!); result }
    end

    context 'when PDF content is empty' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(PdfGenerator).to receive(:call).and_return(success_result(''))
        allow(document).to receive(:fail!)
      end

      it_behaves_like 'failed service result', "Empty PDF content"
    end

    context 'when document state transition fails' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(document).to receive(:start_validation!).and_raise(StandardError, "State error")
        allow(document).to receive(:fail!)
      end

      it_behaves_like 'failed service result', "State error"

      it { expect(document).to receive(:fail!); result }
    end

    context 'when document is already in failed state' do
      before do
        allow(document).to receive(:failed?).and_return(true)
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(document).to receive(:start_validation!).and_raise(StandardError, "Error")
      end

      it { expect(document).not_to receive(:fail!); result }
    end
  end

  describe 'filename generation' do
    around do |example|
      travel_to(Time.at(1234567890)) { example.run }
    end

    before do
      allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
      allow(PdfGenerator).to receive(:call).and_return(success_result(pdf_content))
      allow(document).to receive(:update!)
    end

    context 'with SVG file extension' do
      before { document.original_file_name = 'test_image.svg' }

      it 'generates timestamped PDF filename' do
        expect(document).to receive(:update!).with(
          generated_file_name: 'test_image_1234567890.pdf'
        )
        result
      end
    end

    context 'without file extension' do
      before { document.original_file_name = 'test_image' }

      it 'generates timestamped PDF filename' do
        expect(document).to receive(:update!).with(
          generated_file_name: 'test_image_1234567890.pdf'
        )
        result
      end
    end

    context 'with complex filename' do
      before { document.original_file_name = 'my-complex_file.name.svg' }

      it 'preserves base name in generated filename' do
        expect(document).to receive(:update!).with(
          generated_file_name: 'my-complex_file.name_1234567890.pdf'
        )
        result
      end
    end
  end
end
