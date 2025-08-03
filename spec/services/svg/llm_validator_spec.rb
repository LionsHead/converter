require 'net/http'
require 'rails_helper'

RSpec.describe Svg::LlmValidator do
  include_context 'service result helpers'
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
    ENV['OPENROUTER_MODEL'] = 'google/gemini-2.5-flash'
  end

  describe '#call' do
    context 'when API key is missing' do
      before { ENV['OPENROUTER_API_KEY'] = '' }

      let(:result) { described_class.call(valid_svg) }

      it_behaves_like 'failed service result', 'OpenRouter API key not configured'
    end

    context 'when SVG content is invalid' do
      context 'with empty content' do
        let(:result) { described_class.call('') }

        it_behaves_like 'failed service result', 'Invalid SVG content'
      end

      context 'with non-SVG content' do
        let(:result) { described_class.call('not an svg') }

        it_behaves_like 'failed service result', 'Invalid SVG content'
      end
    end

    context 'when HTTP request is successful' do
      let(:http_response) { double('response', code: '200', body: mock_api_response.to_json) }
      let(:result) { described_class.call(invalid_svg) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it_behaves_like 'successful service result'

      it 'returns validated SVG data' do
        expect(result.data[:svg_content]).to eq(valid_svg)
        expect(result.data[:issues_found]).to include('Missing xmlns attribute')
        expect(result.data[:warnings]).to eq([])
      end
    end

    context 'when HTTP request fails' do
      let(:http_response) { double('response', code: '401') }
      let(:result) { described_class.call(valid_svg) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it_behaves_like 'failed service result', 'API request failed: 401'
    end

    context 'when response is malformed' do
      let(:http_response) { double('response', code: '200', body: 'invalid json') }
      let(:result) { described_class.call(valid_svg) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(double('http').tap do |http|
          allow(http).to receive(:use_ssl=)
          allow(http).to receive(:read_timeout=)
          allow(http).to receive(:request).and_return(http_response)
        end)
      end

      it_behaves_like 'failed service result', 'Invalid response format from LLM service'
    end

    context 'when network error occurs' do
      let(:result) { described_class.call(valid_svg) }

      before do
        allow(Net::HTTP).to receive(:new).and_raise(Timeout::Error)
      end

      it_behaves_like 'failed service result'

      it 'returns error message as string' do
        expect(result.error).to be_a(String)
      end
    end
  end

  describe 'request structure' do
    let(:service) { described_class.new(valid_svg) }
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
        expect(parsed_body['model']).to eq('google/gemini-2.5-flash')
      end
    end
  end
end
