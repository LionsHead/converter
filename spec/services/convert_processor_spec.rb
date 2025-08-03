require 'rails_helper'

RSpec.describe ConvertProcessor do
  include_context 'service result helpers'
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
        # allow(document).to receive(:save!)
      end

      it_behaves_like 'successful service result'

      it { expect(result.data).to eq(document) }

      it 'should validate document and transition states correctly' do
        expect(document).to receive(:start_validation!).ordered
        expect(document).to receive(:validation_succeed!).ordered
        expect(document).to receive(:complete!).ordered

        result
      end

      it 'should attach PDF with correct attributes' do
        expect(document.pdf_file).to receive(:attach).with(
          hash_including(
            io: be_a(StringIO),
            filename: end_with('.pdf'),
            content_type: 'application/pdf'
          )
        )
        result
      end

      it 'should update document with generated filename' do
        result
        expect(document.generated_file_name).to end_with('.pdf')
      end
    end

    context 'when SVG content is blank' do
      before do
        allow(document).to receive(:svg_content).and_return('')
      end

      it_behaves_like 'failed service result', 'SVG content is blank'

      it 'should transition to validation failed state' do
        expect(document).to receive(:start_validation!)
        expect(document).to receive(:validation_fail!)
        expect(document).to receive(:fail!)

        result
      end
    end

    context 'when SVG validation fails' do
      let(:validation_error) { "Invalid SVG structure" }

      before do
        allow(SvgValidator).to receive(:call).and_return(failure_result(validation_error))
      end

      it_behaves_like 'failed service result', 'SVG validation failed'

      it 'should transition document to validation failed state' do
        expect(document).to receive(:start_validation!)
        expect(document).to receive(:validation_fail!)
        expect(document).to receive(:fail!)

        result
      end

      it { expect(PdfGenerator).not_to receive(:call); result }
    end

    context 'when PDF generation fails' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(PdfGenerator).to receive(:call).and_return(failure_result("Generation error"))
      end

      it_behaves_like 'failed service result', 'PDF generation failed'

      it 'should transition document to failed state' do
        expect(document).to receive(:fail!)
        result
      end
    end

    context 'when PDF content is empty' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(PdfGenerator).to receive(:call).and_return(success_result(''))
      end

      it_behaves_like 'failed service result', 'Empty PDF content'

      it 'should transition document to failed state' do
        expect(document).to receive(:fail!)
        result
      end
    end

    context 'when document state transition fails' do
      before do
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(document).to receive(:start_validation!).and_raise(StandardError, "State error")
      end

      it_behaves_like 'failed service result', 'State error'

      it 'should transition document to failed state' do
        expect(document).to receive(:fail!)
        result
      end
    end

    context 'when document is already in failed state' do
      before do
        allow(document).to receive(:failed?).and_return(true)
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(document).to receive(:start_validation!).and_raise(StandardError, "Error")
      end

      it 'should not call fail! again' do
        expect(document).not_to receive(:fail!)
        result
      end
    end

    context 'when document is already in validation_failed state' do
      before do
        allow(document).to receive(:failed?).and_return(false)
        allow(document).to receive(:validation_failed?).and_return(true)
        allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
        allow(document).to receive(:start_validation!).and_raise(StandardError, "Error")
      end

      it 'should not call fail! again' do
        expect(document).not_to receive(:fail!)
        result
      end
    end
  end

  describe 'filename generation' do
    around do |example|
      travel_to(Time.at(1234567890)) { example.run }
    end

    before do
      allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
      allow(PdfGenerator).to receive(:call).and_return(success_result(pdf_content))
      allow(document).to receive(:save!)  # Мокаем save! для generated_file_name
    end

    context 'with SVG file extension' do
      before { document.original_file_name = 'test_image.svg' }

      it 'should generate timestamped PDF filename' do
        result
        expect(document.generated_file_name).to eq('test_image_1234567890.pdf')
      end
    end

    context 'without file extension' do
      before { document.original_file_name = 'test_image' }

      it 'should generate timestamped PDF filename' do
        result
        expect(document.generated_file_name).to eq('test_image_1234567890.pdf')
      end
    end

    context 'with complex filename' do
      before { document.original_file_name = 'my-complex_file.name.svg' }

      it 'should preserve base name in generated filename' do
        result
        expect(document.generated_file_name).to eq('my-complex_file.name_1234567890.pdf')
      end
    end
  end

  describe 'PDF generator watermark' do
    let(:watermark_config) { { text: 'Endurance' } }

    before do
      allow(SvgValidator).to receive(:call).and_return(success_result(svg_content))
      allow(PdfGenerator).to receive(:call).and_return(success_result(pdf_content))
      allow(document).to receive(:save!)
    end
    it 'should call PdfGenerator with watermark text' do
      expect(PdfGenerator).to receive(:call).with(
        svg_content,
        page_config: {
          margin: {
            bottom: "50mm",
            left: "20mm",
            right: "20mm",
            top: "50mm"
          }
        },
        watermark_config: watermark_config
      )
      result
    end
  end
end
