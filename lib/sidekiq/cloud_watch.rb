# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/util'

require 'aws-sdk-cloudwatch'

require 'sidekiq/cloud_watch/configuration'
require 'sidekiq/cloud_watch/publisher'
require 'sidekiq/cloud_watch/mock_client'

module Sidekiq
  # Provides realtime metrics reporting directly to CloudWatch, enabling dashboarding and
  # instrumentation like autoscaling through the AWS infrastructure
  # The CloudWatch module provides the entry point for usage.  In your Sidekiq initializer,
  # add a configuration block then enable publishing as such:
  #
  # Sidekiq::CloudWatch.configure do |c|
  #   c.aws_region_name = 'us_east-1'
  #   ...
  # end
  #
  # Sidkiq::CloudWatch.enable!
  module CloudWatch
    VERSION = '0.4.0'.freeze

    class ConfigurationError < StandardError; end

    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def enable! # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Sidekiq.configure_server do |config|
          publisher = Publisher.new(client, leader_is_defined)

          if leader_is_defined
            # Only publish metrics if we are the leader when a leader is defined (sidekiq-ent)
            config.on(:leader) do
              publisher.start
            end
          else
            # Otherwise run a publisher on every node and check if we are the defacto leader
            config.on(:startup) do
              publisher.start
            end
          end

          config.on(:quiet) do
            publisher.quiet if publisher.running?
          end

          config.on(:shutdown) do
            publisher.stop if publisher.running?
          end
        end
      end

      private

      def leader_is_defined
        Sidekiq.options[:lifecycle_events].key?(:leader)
      end

      def client
        return mock_client if configuration.use_mock
        unless configuration.ready?
          raise ConfigurationError, 'AWS region and credentials are not set'
        end

        Aws::Cloudwatch::Client.new(
          region: configuration.aws_region_name,
          access_key_id: configuration.aws_access_key_id,
          secret_access_key: configuration.aws_secret_access_key
        )
      end

      def mock_client
        Sidekiq::CloudWatch::MockClient.new
      end
    end
  end
end
