require 'net/http'
require 'rails_helper'

RSpec.describe Svg::LlmValidator do
  let(:valid_svg) do
    <<~SVG
      <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="40" fill="red"/>
      </svg>
    SVG
  end

  let(:invalid_svg) do
    <<~SVG
      <svg width="100" height="100">
        <circle cx="50" cy="50" r="40" fill="red"
      </svg>
    SVG
  end

  let(:mock_api_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => {
              'fixed' => true,
              'svg_content' => valid_svg,
              'issues_found' => ['Missing xmlns attribute', 'Unclosed circle tag'],
              'warnings' => []
            }.to_json
          }
        }
      ]
    }
  end

  before do
    ENV['OPENROUTER_API_KEY'] = 'test_api_key'
    ENV['OPENROUTER_MODEL'] = 'anthropic/claude-3.5-sonnet'
  end

  describe '#call' do
    context 'when API key is missing' do
      before { ENV['OPENROUTER_API_KEY'] = '' }

      it 'returns failure with configuration error' do
        result = described_class.call(svg_content: valid_svg)

        expect(result).to be_failure
        expect(result.error).to eq('OpenRouter API key not configured')
      end
    end

    context 'when SVG content is invalid' do
      it 'returns failure for empty content' do
        result = described_class.call(svg_content: '')

        expect(result).to be_failure
        expect(result.error).to eq('Invalid SVG content')
      end

      it 'returns failure for non-SVG content' do
        result = described_class.call(svg_content: 'not an svg')

        expect(result).to be_failure
        expect(result.error).to eq('Invalid SVG content')
      end
    end

    context 'when HTTP request is successful' do
      let(:http_response) { double('response', code: '200', body: mock_api_response.to_json) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it 'returns success with validated SVG data' do
        result = described_class.call(svg_content: invalid_svg)

        expect(result).to be_success
        expect(result.data[:valid]).to be true
        expect(result.data[:svg_content]).to eq(valid_svg)
        expect(result.data[:issues_found]).to include('Missing xmlns attribute')
      end
    end

    context 'when HTTP request fails' do
      let(:http_response) { double('response', code: '401') }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it 'returns failure with API error' do
        result = described_class.call(svg_content: valid_svg)

        expect(result).to be_failure
        expect(result.error).to include('API request failed: 401')
      end
    end

    context 'when response is malformed' do
      let(:http_response) { double('response', code: '200', body: 'invalid json') }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it 'returns failure with parsing error' do
        result = described_class.call(svg_content: valid_svg)

        expect(result).to be_failure
        expect(result.error).to eq('Invalid response format from LLM service')
      end
    end

    context 'when network error occurs' do
      before do
        allow(Net::HTTP).to receive(:new).and_raise(Net::TimeoutError)
      end

      it 'returns failure with timeout error' do
        result = described_class.call(svg_content: valid_svg)

        expect(result).to be_failure
        expect(result.error).to be_a(String)
      end
    end
  end

  describe 'request structure' do
    let(:service) { described_class.new(svg_content: valid_svg) }
    let(:http_response) { double('response', code: '200', body: mock_api_response.to_json) }
    let(:request_spy) { double('request') }

    before do
      allow(Net::HTTP::Post).to receive(:new).and_return(request_spy)
      allow(request_spy).to receive(:[]=)
      allow(request_spy).to receive(:body=)

      allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(http_response)
      end)
    end

    it 'uses structured output format' do
      service.call

      expect(request_spy).to have_received(:body=) do |body|
        parsed_body = JSON.parse(body)
        expect(parsed_body['response_format']).to eq({ 'type' => 'json_object' })
        expect(parsed_body['temperature']).to eq(0.7)
        expect(parsed_body['model']).to eq('anthropic/claude-3.5-sonnet')
      end
    end
  end
end
