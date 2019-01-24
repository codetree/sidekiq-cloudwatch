require 'spec_helper'

RSpec.describe Sidekiq::CloudWatch::Publisher do # rubocop:disable Metrics/BlockLength
  let(:stats) do
    instance_double(
      Sidekiq::Stats,
      processed: 123,
      failed: 456,
      enqueued: 6,
      scheduled_size: 1,
      retry_size: 2,
      dead_size: 3,
      queues: queues,
      workers_size: 10,
      processes_size: 5,
      default_queue_latency: 1.23
    )
  end
  let(:queues) { { 'foo' => 1, 'bar' => 2, 'baz' => 3 } }
  let(:processes) do
    [
      Sidekiq::Process.new('busy' => 5, 'concurrency' => 10, 'hostname' => 'foo'),
      Sidekiq::Process.new('busy' => 2, 'concurrency' => 20, 'hostname' => 'bar')
    ]
  end
  let(:client) { Sidekiq::CloudWatch::MockClient.new }
  let(:latency) { double(latency: 1.23) }

  before(:each) do
    allow(Sidekiq::Stats).to receive(:new).and_return(stats)
    allow(Sidekiq::ProcessSet).to receive(:new).and_return(processes)
    allow(Sidekiq::Queue).to receive(:new).with(/foo|bar|baz/).and_return(latency)
  end

  let(:leader_defined) { true }

  subject(:publisher) { Sidekiq::CloudWatch::Publisher.new(client, leader_defined) }

  describe '#publish' do
    it 'publishes sidekiq metrics to cloudwatch with correct_keys' do
      expect(client).to receive(:put_metric_data).with(hash_including(:namespace, :metric_data))
      publisher.publish
    end

    it 'publishes sidekiq metrics to cloudwatch in Sidekiq namespace' do
      expect(client).to receive(:put_metric_data).with(hash_including(namespace: 'Sidekiq'))
      publisher.publish
    end

    context 'with 30 queues' do
      before(:each) do
        allow(Sidekiq::Queue).to receive(:new).with(/queue.*/).and_return(latency)
      end
      let(:queues) { 30.times.each_with_object({}) { |i, hash| hash["queue#{i}"] = i } }

      it 'publishes sidekiq metrics to cloudwatch for lots of queues in batches of 20' do
        expect(client).to receive(:put_metric_data).exactly(4).times

        publisher.publish
      end
    end
  end
end
