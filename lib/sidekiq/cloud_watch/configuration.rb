module Sidekiq
  module CloudWatch
    # Provides a configuration interface for Sidekiq::CloudWatch
    class Configuration
      attr_accessor :use_mock, :aws_region_name, :aws_access_key_id, :aws_secret_access_key, :leader

      def initialize
        @leader                 = true
        @use_mock               = false
      end

      # if any aws keys are not defined, then configuration is not ready
      def ready?
        !aws_region_name.nil? &&
          !aws_access_key_id.nil? &&
          !aws_secret_access_key.nil?
      end
    end
  end
end
