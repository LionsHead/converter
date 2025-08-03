require 'rails_helper'

RSpec.describe Pdf::TemplateBuilder do
  let(:svg_content) { '<svg><circle cx="50" cy="50" r="40" fill="red" /></svg>' }
  let(:watermark_config) { { text: 'Test Watermark' } }

  describe '#call' do
    context 'with valid parameters' do
      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it { expect(service.call).to be_success }

      it 'returns HTML content' do
        result = service.call
        expect(result.data).to be_a(String)
        expect(result.data).to include('<!DOCTYPE html>')
      end

      it 'includes SVG content in result' do
        result = service.call
        expect(result.data).to include(svg_content)
      end

      it 'includes watermark overlay' do
        result = service.call
        expect(result.data).to include('watermark-overlay')
        expect(result.data).to include('background-image: url(\'data:image/svg+xml;base64,')
      end

      it 'includes current year in footer' do
        result = service.call
        expect(result.data).to include("© #{Time.now.year}")
      end

      it 'contains watermark text in base64 encoded SVG' do
        result = service.call
        base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
        expect(base64_match).not_to be_nil

        decoded_svg = Base64.decode64(base64_match[1])
        expect(decoded_svg).to include('Test Watermark')
      end

      it 'escapes HTML in watermark text' do
        service = described_class.new(svg_content, watermark_config: { text: '<script>alert("xss")</script>' })
        result = service.call
        base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
        decoded_svg = Base64.decode64(base64_match[1])
        expect(decoded_svg).to include('&lt;script&gt;')
      end
    end

    context 'with custom watermark config' do
      let(:custom_config) do
        {
          text: 'Custom Text',
          size: { width: 300, height: 150 },
          font_size: 32,
          opacity: 0.1,
          rotation: -30
        }
      end

      subject(:service) { described_class.new(svg_content, watermark_config: custom_config) }

      it 'uses custom configuration in SVG pattern' do
        result = service.call
        base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
        decoded_svg = Base64.decode64(base64_match[1])

        expect(decoded_svg).to include('Custom Text')
        expect(decoded_svg).to include('width="300"')
        expect(decoded_svg).to include('height="150"')
        expect(decoded_svg).to include('font-size="32"')
        expect(decoded_svg).to include('rgba(0,0,0,0.1)')
        expect(decoded_svg).to include('rotate(-30')
      end

      it 'uses custom repeat size in CSS' do
        result = service.call
        expect(result.data).to include('background-size: 250px 150px')
      end
    end

    context 'with blank SVG content' do
      let(:svg_content) { '' }

      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it { expect(service.call).to be_failure }

      it 'returns appropriate error message' do
        result = service.call
        expect(result.error).to eq('SVG content is blank')
      end
    end

    context 'with nil SVG content' do
      let(:svg_content) { nil }

      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it { expect(service.call).to be_failure }
    end

    context 'with blank watermark text' do
      let(:watermark_config) { { text: '' } }

      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it { expect(service.call).to be_failure }

      it 'returns appropriate error message' do
        result = service.call
        expect(result.error).to eq('Watermark text is blank')
      end
    end

    context 'with nil watermark text' do
      let(:watermark_config) { { text: nil } }

      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it { expect(service.call).to be_failure }
    end

    context 'with empty watermark config' do
      let(:watermark_config) { {} }

      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      it 'uses default watermark text' do
        result = service.call
        expect(result).to be_success

        base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
        decoded_svg = Base64.decode64(base64_match[1])
        expect(decoded_svg).to include('Maxa Watermark')
      end
    end

    context 'when exception occurs during HTML generation' do
      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      before do
        allow(service).to receive(:build_content).and_raise(StandardError, 'Generation failed')
      end

      it { expect(service.call).to be_failure }

      it 'returns error message' do
        result = service.call
        expect(result.error).to eq('Generation failed')
      end
    end

    context 'when Base64 encoding fails' do
      subject(:service) { described_class.new(svg_content, watermark_config: watermark_config) }

      before do
        allow(Base64).to receive(:strict_encode64).and_raise(StandardError, 'Encoding failed')
      end

      it { expect(service.call).to be_failure }
    end
  end

  describe 'default configuration' do
    subject(:service) { described_class.new(svg_content) }

    it 'uses default watermark config when none provided' do
      result = service.call
      expect(result).to be_success

      base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
      decoded_svg = Base64.decode64(base64_match[1])
      expect(decoded_svg).to include('Maxa Watermark')
    end

    it 'uses default configuration values' do
      result = service.call
      base64_match = result.data.match(/data:image\/svg\+xml;base64,([^']+)/)
      decoded_svg = Base64.decode64(base64_match[1])

      expect(decoded_svg).to include('width="250"')
      expect(decoded_svg).to include('height="250"')
      expect(decoded_svg).to include('font-size="48"')
      expect(decoded_svg).to include('rgba(0,0,0,0.1)')
      expect(decoded_svg).to include('rotate(-40')

      expect(result.data).to include('background-size: 250px 150px')
    end
  end
end
