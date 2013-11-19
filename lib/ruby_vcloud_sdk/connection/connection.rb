require "base64"
require "rest_client"

module VCloudSdk
  module Connection
    class Connection
      ACCEPT = "application/*+xml;version=#{VCloudSdk::Client::VCLOUD_VERSION_NUMBER}"

      REST_THROTTLE = {
        min: 0,
        max: 1,
      }

      private_constant :ACCEPT, :REST_THROTTLE

      def initialize(url, request_timeout = nil,
          rest_client = nil, site = nil, file_uploader = nil, rest_throttle = nil)
        @rest_throttle = rest_throttle || REST_THROTTLE

        construct_rest_logger
        Config.configure(rest_logger: @rest_logger)

        rest_client = RestClient unless rest_client
        rest_client.log = @rest_logger
        request_timeout = 60 unless request_timeout
        @site = site || rest_client::Resource.new(
                          url,
                          timeout: request_timeout)
        @file_uploader = file_uploader || FileUploader
      end

      def connect(username, password)
        login_password = "#{username}:#{password}"
        auth_header_value = "Basic #{Base64.encode64(login_password)}"
        response = @site[login_url].post(
            Authorization: auth_header_value, Accept: ACCEPT)
        Config.logger.debug(response)
        @cookies = response.cookies
        unless @cookies["vcloud-token"].gsub!("+", "%2B").nil?
          Config.logger.debug("@cookies: #{@cookies.inspect}.")
        end
        wrap_response(response)
      end

      # GET an object from REST and return the unmarshalled object
      def get(destination)
        @rest_logger.info "#{__method__.to_s.upcase} #{delay}\t " +
                           "#{self.class.get_href(destination)}"
        sleep(delay)
        response = @site[get_nested_resource(destination)].get(
            Accept: ACCEPT,
            cookies: @cookies)
        @rest_logger.debug(response)
        wrap_response(response)
      end

      def post(destination, data, content_type = "*/*")
        @rest_logger.info "#{__method__.to_s.upcase} #{delay}\t " +
                           "#{self.class.get_href(destination)}"
        sleep(delay)
        if content_type == "*/*"
          @rest_logger.debug(
            "Warning: content type not specified.  Default to '*/*'")
        end
        @rest_logger.info("#{__method__.to_s.upcase} data:#{data.to_s}")
        response = @site[get_nested_resource(destination)].post(data.to_s, {
            Accept: ACCEPT,
            cookies: @cookies,
            content_type: content_type
        })
        fail ApiRequestError if http_error?(response)
        @rest_logger.debug(response)
        wrap_response(response)
      end

      def put(destination, data, content_type = "*/*")
        @rest_logger.info "#{__method__.to_s.upcase} #{delay}\t " +
                           "#{self.class.get_href(destination)}"
        sleep(delay)
        unless content_type
          @rest_logger.debug(
            "Warning: content type not specified.  Default to '*/*'")
        end
        @rest_logger.info("#{__method__.to_s.upcase} data:#{data.to_s}")
        response = @site[get_nested_resource(destination)].put(data.to_s,
            Accept: ACCEPT,
            cookies: @cookies,
            content_type: content_type
        )
        fail ApiRequestError if http_error?(response)
        @rest_logger.debug((response && !response.strip.empty?) ?
          response : "Received empty response.")
        if response && !response.strip.empty?
          wrap_response(response)
        else
          nil
        end
      end

      def delete(destination)
        @rest_logger.info "#{__method__.to_s.upcase} #{delay}\t " +
                           "#{self.class.get_href(destination)}"
        sleep(delay)
        response = @site[get_nested_resource(destination)].delete(
            Accept: ACCEPT,
            cookies: @cookies
        )
        @rest_logger.debug(response)
        if response && !response.strip.empty?
          wrap_response(response)
        else
          nil
        end
      end

      # The PUT method in rest-client cannot handle large files because it
      # does not use the underlying Net::HTTP body_stream attribute.
      # Without that, it will not use chunked transfer-encoding.  It also
      # reads in the whole file at once.
      def put_file(destination, file)
        href = self.class.get_href(destination)
        @rest_logger.info "#{__method__.to_s.upcase}\t#{href}"
        response = @file_uploader.upload(href, file, @cookies)
        response
      end

      private

      def wrap_response(response)
        VCloudSdk::Xml::WrapperFactory.wrap_document response
      end

      def login_url
        return @login_url if @login_url
        default_login_url = "/api/sessions"

        begin
          url_node = get("/api/versions")
          if url_node.nil?
            Config.logger.warn %Q{
              Unable to find version=#{VCLOUD_VERSION_NUMBER}. Default to #{default_login_url}
            }
            @login_url = default_login_url
          else
            # Typically url_content is the full URL such as "https://10.146.21.135/api/sessions"
            # In this case we need to trim the beginning of the url string
            @login_url = get_nested_resource(url_node.login_url.content)
          end
        rescue => ex
          Config.logger.warn %Q{
            Caught exception when retrieving login url:
            #{ex.to_s}"

            Default to #{default_login_url}
          }

          @login_url = default_login_url
        end
      end

      def construct_rest_logger
        Config.logger.debug("constructing rest_logger")

        config_logger_dev = Config.logger.instance_eval { @logdev }.dev
        if config_logger_dev.respond_to?(:path)
          rest_log_filename = File.join(
            File.dirname(Config.logger.instance_eval { @logdev }.dev.path),
            "rest")
          log_file = File.open(rest_log_filename, "w")
          log_file.sync = true
          @rest_logger = Logger.new(log_file)
        else
          @rest_logger = Config.logger
        end

        @rest_logger.level = Config.logger.level
        @rest_logger.formatter = Config.logger.formatter
      end

      def log_exceptions(e)
        if e.is_a? RestClient::Exception
          Config.logger.error("HTTP Code: #{e.http_code}")
          Config.logger.error("HTTP Body: #{e.http_body}")
          Config.logger.error("Message: #{e.message}")
          Config.logger.error("Response: #{e.response}")
        end
      end

      def delay
        @rest_throttle[:min] + rand(@rest_throttle[:max] -
          @rest_throttle[:min])
      end

      def get_nested_resource(destination)
        href = self.class.get_href(destination)
        if href.is_a?(String)
          uri = URI.parse(href)
          if uri.query.nil?
            uri.path
          else
            "#{uri.path}?#{uri.query}"
          end
        else
          fail ApiError,
               "href is not a string. href:#{href.inspect}, dst:#{destination}."
        end
      end

      def http_error?(response)
        response.respond_to?(:code) && response.code.to_i >= 400
      end

      class << self
        def get_href(destination)
          if destination.is_a?(Xml::Wrapper) && destination.href
            destination.href
          else
            destination
          end
        end
      end
    end
  end
end
