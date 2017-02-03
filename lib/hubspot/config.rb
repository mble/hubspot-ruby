require 'logger'

module Hubspot
  class Config
    CONFIG_KEYS = %i(hapikey use_oauth2 oauth2_access_token base_url portal_id logger)
    DEFAULT_LOGGER = Logger.new('/dev/null')
    DEFAULT_BASE_URL = 'https://api.hubapi.com'.freeze

    class << self
      attr_accessor *CONFIG_KEYS

      def configure(config)
        @hapikey = config[:hapikey]
        @use_oauth2 = config[:use_oauth2]
        @oauth2_access_token = config[:oauth2_access_token]
        @base_url = config[:base_url] || DEFAULT_BASE_URL
        @portal_id = config[:portal_id]
        @logger = config[:logger] || DEFAULT_LOGGER
        self
      end

      def reset!
        @hapikey = nil
        @use_oauth2 = nil
        @base_url = DEFAULT_BASE_URL
        @portal_id = nil
        @logger = DEFAULT_LOGGER
      end

      def ensure!(*params)
        params.each do |p|
          raise Hubspot::ConfigurationError, "'#{p}' not configured" unless instance_variable_get "@#{p}"
        end
      end
    end

    reset!
  end
end
