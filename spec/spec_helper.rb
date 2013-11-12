require "simplecov"
require "simplecov-rcov"

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
end

require "yaml"
require "ruby_vcloud_sdk"

module VCloudSdk
  module Test

    class << self
      def spec_asset(filename)
        File.expand_path(File.join(File.dirname(__FILE__), "assets", filename))
      end

      def test_configuration
        @@test_config ||= YAML.load_file(spec_asset("test-config.yml"))
      end

      def properties
        test_configuration["properties"]
      end

      def get_vcd_settings
        vcds = properties["vcds"]
        raise "Invalid number of VCDs" unless vcds.size == 1
        vcds[0]
      end

      def vcd_settings
        @@settings ||= get_vcd_settings
      end

      def generate_unique_name
        SecureRandom.uuid
      end

      def compare_xml(a, b)
        a.diff(b) do |change, node|
          # " " Means no difference.  "+" means addition and "-" means deletion.
          return false if change != " " && node.to_s.strip().length != 0
        end
        true
      end

      def rest_logger(logger)
        rest_log_filename = File.join(File.dirname(
          logger.instance_eval { @logdev }.dev.path), "rest")
        log_file = File.open(rest_log_filename, "w")
        log_file.sync = true
        rest_logger = Logger.new(log_file || STDOUT)
        rest_logger.level = logger.level
        rest_logger.formatter = logger.formatter
        def rest_logger.<<(str)
          self.debug(str.chomp)
        end
        rest_logger
      end

      def verify_settings(obj, settings)
        settings.each do |instance_variable_name, target_value|
          instance_variable = obj.instance_variable_get(instance_variable_name)
          instance_variable.should == target_value
        end
      end

      def mock_connection(logger, url)
        VCloudSdk::Config.configure(logger: logger)

        rest_client = VCloudSdk::Mocks::RestClient.new(url)
        VCloudSdk::Connection::Connection.new(url, nil, nil, rest_client)
      end

      def mock_session(logger, url)
        time_limit_sec = {
          default: 120,
          delete_vapp_template: 120,
          delete_vapp: 3,
          delete_media: 120,
          instantiate_vapp_template: 300,
          power_on: 3,
          power_off: 3,
          undeploy: 3,
          process_descriptor_vapp_template: 300,
          http_request: 240,
        }

        options = {}
        options[:time_limit_sec] = time_limit_sec
        # Note: need to run "mock_connection" first and then stub method "new"
        conn = VCloudSdk::Test.mock_connection(logger, url)
        VCloudSdk::Connection::Connection.stub(:new) { conn }
        VCloudSdk::Session.new(url, nil, nil, options)
      end
    end

    module DefaultSetting
      VCLOUD_URL = "https://10.146.21.135"
      VCLOUD_USERNAME = "dev_mgr@dev"
      VCLOUD_PWD = "vmware"
      VDC_NAME = "tempest"
      CATALOG_NAME = "cloudfoundry"
      STORAGE_PROFILE_NAME = "large"
      CATALOG_NAME_TO_CREATE = "dev test catalog"
      VAPP_NAME = "PCF vApp"
      NETWORK_NAME = "tempest_vdc_network"
    end
  end

  module Xml

    class Wrapper
      def ==(other)
        @root.diff(other.node) do |change, node|
          # " " Means no difference, "+" means addition and "-" means deletion
          return false if change != " " && node.to_s.strip().length != 0
        end
        true
      end
    end

  end

  class Config
    class << self
      def logger()
        log_file = VCloudSdk::Test::properties["log_file"]
        FileUtils.mkdir_p(File.dirname(log_file))
        logger = Logger.new(log_file)
        logger.level = Logger::DEBUG
        logger
      end
    end
  end

end



module Kernel

  def with_thread_name(name)
    old_name = Thread.current[:name]
    Thread.current[:name] = name
    yield
  ensure
    Thread.current[:name] = old_name
  end

end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true  # for RSpec-3

  c.after :all do
    FileUtils.rm_rf(File.dirname(VCloudSdk::Test::properties["log_file"]))
  end
end
