RSpec.shared_examples 'successful service result' do |expected_data = nil|
  it 'returns successful result' do
    expect(result).to be_success
    expect(result).not_to be_failure
    expect(result.error).to be_nil
  end

  if expected_data
    it 'returns expected data' do
      expect(result.data).to eq(expected_data)
    end
  end
end

RSpec.shared_examples 'failed service result' do |expected_error = nil|
  it 'returns failed result' do
    expect(result).to be_failure
    expect(result).not_to be_success
    expect(result.data).to be_nil
  end

  if expected_error
    it 'returns expected error' do
      expect(result.error).to include(expected_error)
    end
  end
end

RSpec::Matchers.define :be_successful_service_result do
  match do |result|
    result.success? && result.error.nil?
  end

  failure_message do |result|
    "expected service result to be successful, but got error: #{result.error}"
  end
end

RSpec::Matchers.define :be_failed_service_result do |expected_error|
  match do |result|
    result.failure? && (expected_error.nil? || result.error.include?(expected_error))
  end

  failure_message do |result|
    if result.success?
      "expected service result to fail, but it was successful"
    else
      "expected error to include '#{expected_error}', but got '#{result.error}'"
    end
  end
end

# Helper methods for creating service results in tests
RSpec.shared_context 'service result helpers' do
  def success_result(data)
    BaseService::ServiceResult.new(success: true, data: data)
  end

  def failure_result(error)
    BaseService::ServiceResult.new(success: false, error: error)
  end
end
