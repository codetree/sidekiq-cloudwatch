module Sidekiq
  module CloudWatch
    class MockClientError < StandardError; end

    # Provides a mock client to test basic functionality without sending anything to Cloudwatch
    class MockClient
      def initialize; end

      def put_metric_data(args)
        raise MockClientError, 'Missing namespace argument' if args[:namespace].nil?
        raise MockClientError, 'Missing metric_data argument' if args[:metric_data].nil?

        true
      end
    end
  end
end
