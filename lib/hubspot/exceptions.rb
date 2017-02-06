module Hubspot
  class RequestError < StandardError
    attr_accessor :response

    def initialize(response, message = nil)
      message += "\n" if message
      me = super("#{message}Response body: #{response.body}",)
      me.response = response
      me
    end
  end

  class AuthenticationError < StandardError
    attr_accessor :message, :status, :engagement

    def initialize(response)
      parsed = response.parsed_response
      @engagement = parsed['engagement']
      @message = parsed['message']
      @status = parsed['status']
      super "status: #{@status} message: #{@message} engagement_info: #{@engagement}"
    end
  end

  class ConfigurationError < StandardError; end
  class MissingInterpolation < StandardError; end
  class ContactExistsError < RequestError; end
  class InvalidParams < StandardError; end
  class ApiError < StandardError; end
end
