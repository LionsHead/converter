require 'rails_helper'

RSpec.describe HtmlBuilder do
  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:watermark_text) { 'Sample Watermark' }

  describe '#call' do
    context 'with valid parameters' do
      subject(:result) { described_class.new(svg_content, watermark_text).call }

      it 'returns success with HTML content' do
        expect(result).to be_success
        expect(result.data).to be_a(String)
        expect(result.data).to include('<!DOCTYPE html>')
      end

      it 'includes SVG content in result' do
        expect(result.data).to include(svg_content)
      end

      it 'includes watermark base64 in result' do
        expect(result.data).to include('watermark-overlay')
        expect(result.data).to include('background-image: url(\'data:image/svg+xml;base64,')
      end
    end

    context 'with blank SVG content' do
      let(:svg_content) { '' }

      it 'returns failure' do
        result = described_class.new(svg_content, watermark_text).call
        expect(result).to be_failure
        expect(result.error).to eq("SVG content is blank")
      end
    end

    context 'with blank watermark text' do
      let(:watermark_text) { '' }

      it 'returns failure' do
        result = described_class.new(svg_content, watermark_text).call
        expect(result).to be_failure
        expect(result.error).to eq("Watermark text is blank")
      end
    end

    context 'when exception occurs' do
      before do
        allow_any_instance_of(described_class).to receive(:build_content).and_raise(StandardError, "Test error")
      end

      it 'returns failure with error message' do
        result = described_class.new(svg_content, watermark_text).call
        expect(result).to be_failure
        expect(result.error).to eq("Test error")
      end
    end
  end
end
