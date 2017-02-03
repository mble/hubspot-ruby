module Hubspot
  class Connection
    include HTTParty

    class << self
      def get_json(path, opts)
        set_oauth2_headers

        url = generate_url(path, opts)
        response = get(url, format: :json)
        log_request_and_response url, response
        raise Hubspot::RequestError, response unless response.success?
        response.parsed_response
      end

      def post_json(path, opts)
        no_parse = opts[:params].delete(:no_parse) { false }
        set_oauth2_headers

        url = generate_url(path, opts[:params])
        response = post(url, body: opts[:body].to_json, headers: { 'Content-Type' => 'application/json' }, format: :json)
        log_request_and_response url, response, opts[:body]
        raise Hubspot::RequestError, response unless response.success?

        no_parse ? response : response.parsed_response
      end

      def put_json(path, opts)
        set_oauth2_headers

        url = generate_url(path, opts[:params])
        response = put(url, body: opts[:body].to_json, headers: { 'Content-Type' => 'application/json' }, format: :json)
        log_request_and_response url, response, opts[:body]
        raise Hubspot::RequestError, response unless response.success?
        response.parsed_response
      end

      def delete_json(path, opts)
        set_oauth2_headers

        url = generate_url(path, opts)
        response = delete(url, format: :json)
        log_request_and_response url, response, opts[:body]
        raise Hubspot::RequestError, response unless response.success?
        response
      end

      protected

      def set_oauth2_headers
        # TODO: Better to have different connection strategies depending on configuration
        raise Hubspot::ConfigurationError, 'OAuth2 access token must be provided when using OAuth2' if Hubspot::Config.use_oauth2 && !oauth2_usage_valid?
        headers 'Authorization' => "Bearer #{Hubspot::Config.oauth2_access_token}" if Hubspot::Config.use_oauth2 && oauth2_usage_valid?
      end

      def set_hapikey(params)
        params['hapikey'] = Hubspot::Config.hapikey
      end

      def set_portal_id(path, params)
        if path =~ /:portal_id/
          Hubspot::Config.ensure! :portal_id
          params['portal_id'] = Hubspot::Config.portal_id
        end
      end

      def oauth2_usage_valid?
        Hubspot::Config.oauth2_access_token.present? &&
        Hubspot::Config.hapikey.blank?
      end

      def disable_hapikey_auth?(options)
        options[:hapikey] == false || Hubspot::Config.use_oauth2
      end

      def interpolate_path(path, params)
        params.each do |k, v|
          if path.match(":#{k}")
            path.gsub!(":#{k}", CGI.escape(v.to_s))
            params.delete(k)
          end
        end
        raise Hubspot::MissingInterpolation, 'Interpolation not resolved' if path =~ /:/
      end

      def generate_query(params)
        params.map do |k, v|
          v.is_a?(Array) ? v.map { |value| param_string(k, value) } : param_string(k, v)
        end.join('&')
      end

      def log_request_and_response(uri, response, body = nil)
        Hubspot::Config.logger.info "Hubspot: #{uri}.\nBody: #{body}.\nResponse: #{response.code} #{response.body}"
      end

      def generate_url(path, params = {}, options = {})
        Hubspot::Config.ensure! :hapikey unless Hubspot::Config.use_oauth2
        path = path.clone
        params = params.clone
        base_url = options[:base_url] || Hubspot::Config.base_url

        set_hapikey(params) unless disable_hapikey_auth? options
        set_portal_id path, params
        interpolate_path path, params

        query = generate_query params

        path += path.include?('?') ? '&' : '?' if query.present?
        base_url + path + query
      end

      # convert into milliseconds since epoch
      def converted_value(value)
        value.is_a?(Time) ? (value.to_i * 1000) : CGI.escape(value.to_s)
      end

      def param_string(key, value)
        case key
        when /range/
          raise 'Value must be a range' unless value.is_a?(Range)
          "#{key}=#{converted_value(value.begin)}&#{key}=#{converted_value(value.end)}"
        when /^batch_(.*)$/
          key = Regexp.last_match(1).gsub(/(_.)/) { |w| w.last.upcase }
          "#{key}=#{converted_value(value)}"
        else
          "#{key}=#{converted_value(value)}"
        end
      end
    end
  end

  class FormsConnection < Connection
    follow_redirects true

    def self.submit(path, opts)
      url = generate_url(path, opts[:params], base_url: 'https://forms.hubspot.com', hapikey: false)
      post(url, body: opts[:body], headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
    end
  end
end
