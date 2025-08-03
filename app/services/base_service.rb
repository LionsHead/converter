class BaseService
  class ServiceResult
    attr_reader :data, :error

    def initialize(success:, data: nil, error: nil)
      @success = success
      @data = data
      @error = error
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  def success(data = nil)
    ServiceResult.new(success: true, data: data)
  end

  def failure(error:, data: nil)
    ServiceResult.new(success: false, error: error, data: data)
  end

  def info(message)
    Rails.logger.info message
  end

  def error(message)
    Rails.logger.error message
  end
end
