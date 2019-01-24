# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/util'

require 'aws-sdk-cloudwatch'

module Sidekiq
  module CloudWatch
    # Publish events to AWS Cloudwatch on a set interval.  Include all standard Sidekiq metrics
    class Publisher # rubocop:disable Metrics/ClassLength
      include Sidekiq::Util

      INTERVAL =      60 # time, in seconds, between each publishing of the metrics
      NAMESPACE =     'Sidekiq'.freeze
      UNIT_COUNT =    'Count'.freeze
      UNIT_SECONDS =  'Seconds'.freeze
      UNIT_PERCENT =  'Percent'.freeze

      def initialize(client, leader_is_defined)
        @client = client
        @leader_is_defined = leader_is_defined
      end

      def start
        logger.info { 'Starting Sidekiq CloudWatch Publisher' }

        @stop = false
        @thread = safe_thread('Sidekiq Coudwatch Publisher', &method(:run))
      end

      def running?
        !@thread.nil? && @thread.alive?
      end

      def quiet
        logger.info { 'Quieting Sidekiq CloudWatch Publisher' }
        @stop = true
      end

      def stop
        logger.info { 'Stopping Sidekiq CloudWatch Publisher' }
        @stop = true
        @thread.wakeup
        @thread.join
      end

      def run
        logger.info { 'Started Sidekiq CloudWatch Publisher' }

        # Publish stats every INTERVAL seconds, sleeping as required between runs
        tick = Time.now.to_f
        until @stop
          logger.info { 'Publishing to CloudWatch' }
          publish if leader?
          tick = start_sleeping(tick)
        end

        logger.info { 'Stopped Sidekiq CloudWatch Publisher' }
      end

      def publish
        collect_all_metrics.each_slice(20) do |some_metrics|
          # We can only put 20 metrics at a time
          @client.put_metric_data(namespace: NAMESPACE, metric_data: some_metrics)
        end
      end

      private

      def start_sleeping(tick)
        now = Time.now.to_f
        tick = [tick + INTERVAL, now].max
        sleep(tick - now) if tick > now
        tick
      end

      def collect_all_metrics
        stats = Sidekiq::Stats.new

        # collect aggregate stats for Sidekiq overall
        collect_general_metrics(stats) +
          collect_calculated_metrics(stats) +
          collect_processes_metrics(stats) +
          collect_queues_metrics(stats)
      end

      def collect_general_metrics(stats)
        [
          prepare_metric('ProcessedJobs',       stats.processed,                  UNIT_COUNT),
          prepare_metric('FailedJobs',          stats.failed,                     UNIT_COUNT),
          prepare_metric('EnqueuedJobs',        stats.enqueued,                   UNIT_COUNT),
          prepare_metric('ScheduledJobs',       stats.scheduled_size,             UNIT_COUNT),
          prepare_metric('RetryJobs',           stats.retry_size,                 UNIT_COUNT),
          prepare_metric('DeadJobs',            stats.dead_size,                  UNIT_COUNT),
          prepare_metric('Workers',             stats.workers_size,               UNIT_COUNT)
        ]
      end

      def collect_calculated_metrics(stats)
        [
          prepare_metric('Capacity',            calculate_capacity(processes),    UNIT_COUNT),
          prepare_metric('Utilization',         calculate_utilization(processes), UNIT_PERCENT),
          prepare_metric('DefaultQueueLatency', stats.default_queue_latency,      UNIT_SECONDS)
        ]
      end

      def collect_processes_metrics(stats)
        metrics = [
          prepare_metric('Processes', stats.processes_size, UNIT_COUNT)
        ]

        metrics + processes.map do |process|
          dimensions = [{ name: 'Hostname', value: process['hostname'] }]
          value = process['busy'] / process['concurrency'].to_f * 100.0
          prepare_metric('Utilization', value, UNIT_PERCENT, dimensions)
        end
      end

      def collect_queues_metrics(stats)
        metrics = []
        stats.queues.map do |(queue_name, queue_size)|
          dimensions = [{ name: 'QueueName', value: queue_name }]
          queue_latency = Sidekiq::Queue.new(queue_name).latency
          metrics << prepare_metric('QueueSize', queue_size, UNIT_COUNT, dimensions)
          metrics << prepare_metric('QueueLatency', queue_latency, UNIT_SECONDS, dimensions)
        end
        metrics
      end

      def prepare_metric(name, value, unit, dimension = nil)
        {
          metric_name: name,
          dimension: dimension,
          timestamp: Time.now,
          value: value,
          unit: unit
        }.reject { |_k, v| v.nil? }
      end

      def leader?
        return true if @leader_is_defined # assumes we are the leader if we are running

        identity == defacto_leader
      end

      def defacto_leader
        running_processes.map(&:identity).min
      end

      def process_set
        @process_set ||= Sidekiq::ProcessSet.new
      end

      def processes
        @processes ||= process_set.to_enum(:each).to_a
      end

      # Returns the total number of workers across all processes
      def calculate_capacity(processes)
        sum = 0
        processes.each do |process|
          sum += process['concurrency']
        end
        sum
      end

      # Returns busy / concurrency averaged across processes (for scaling)
      def calculate_utilization(processes)
        sum = 0.to_f
        processes.map do |process|
          sum += process['busy'] / process['concurrency'].to_f
        end
        sum / processes.size.to_f
      end
    end
  end
end
