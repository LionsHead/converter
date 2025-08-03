require "net/http"
require "json"
require "uri"

class Svg::LlmValidator < BaseService
  API_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions".freeze

  def initialize(svg_content:)
    @svg_content = svg_content
    @api_key = ENV.fetch("OPENROUTER_API_KEY")
    @model = ENV.fetch("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet")
  end

  def call
    return failure(error: "OpenRouter API key not configured") if @api_key.blank?
    return failure(error: "Invalid SVG content") unless valid_svg?

    validate_and_fix_svg
  rescue StandardError => e
    error("SVG validation failed: #{e.message}")
    failure(error: e.message)
  end

  private

  def valid_svg?
    @svg_content.present? && @svg_content.include?("<svg")
  end

  def validate_and_fix_svg
    response = make_api_request

    if response.code == "200"
      parse_response(response)
    else
      failure(error: "API request failed: #{response.code}")
    end
  end

  def make_api_request
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    http.request(request)
  end

  def request_body
    {
      model: @model,
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: @svg_content
        }
      ],
      response_format: {
        type: "json_object"
      },
      temperature: 0.7,
      max_tokens: 4000
    }
  end

  def system_prompt
    <<~PROMPT
      You are an SVG validation and repair expert. Your task is to analyze the provided SVG content, identify and fix any issues, and return a JSON response with the results. Follow these instructions carefully:

      1. First, you will be provided with the SVG content to analyze:

      <svg_content>
      {{SVG_CONTENT}}
      </svg_content>

      2. Analyze the SVG content for any issues or errors. Pay close attention to the following common problems:
        - Missing or incorrect XML declaration
        - Unclosed tags
        - Invalid attribute values
        - Missing required attributes (width, height, viewBox)
        - Malformed paths
        - Invalid color values
        - Namespace issues

      3. After analyzing the SVG, create a JSON response with the following structure:
        {
          "fixed": true/false,
          "svg_content": "corrected SVG content here",
          "issues_found": ["list of issues that were fixed"],
          "warnings": ["list of potential issues or suggestions"]
        }

      4. When fixing issues:
        - If you find and fix any issues, set "fixed" to true.
        - Place the corrected SVG content in the "svg_content" field.
        - List all issues you fixed in the "issues_found" array.
        - If you notice any potential issues or have suggestions for improvement, add them to the "warnings" array.

      5. If the SVG is already valid and doesn't require any fixes:
        - Set "fixed" to false.
        - Place the original SVG content in the "svg_content" field.
        - Leave the "issues_found" array empty.
        - You may still add any suggestions or potential improvements to the "warnings" array.

      6. Always ensure that the final SVG content in your response is valid, well-formed, and can be rendered properly.

      7. Provide your response in the following format:

      {
        "fixed": true/false,
        "svg_content": "corrected SVG content here",
        "issues_found": ["list of issues that were fixed"],
        "warnings": ["list of potential issues or suggestions"]
      }
    PROMPT
  end

  def parse_response(response)
    result = JSON.parse(response.body)
    content = result.dig("choices", 0, "message", "content")

    return failure(error: "Empty response from LLM service") if content.blank?

    svg_data = JSON.parse(content)

    success({
      valid: svg_data["valid"],
      svg_content: svg_data["svg_content"],
      issues_found: svg_data["issues_found"] || [],
      warnings: svg_data["warnings"] || []
    })
  rescue JSON::ParserError => e
    error("Failed to parse LLM response: #{e.message}")
    failure(error: "Invalid response format from LLM service")
  end
end
