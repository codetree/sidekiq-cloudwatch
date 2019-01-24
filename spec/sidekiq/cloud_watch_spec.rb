require 'spec_helper'

RSpec.describe Sidekiq::CloudWatch do # rubocop:disable Metrics/BlockLength
  # Sidekiq.options does a Sidekiq::DEFAULTS.dup which retains the same values, so
  # Sidekiq.options[:lifecycle_events] IS Sidekiq::DEFAULTS[:lifecycle_events] and
  # is mutable, so Sidekiq.options = nil will again Sidekiq::DEFAULTS.dup and get
  # the same Sidekiq::DEFAULTS[:lifecycle_events]. So we have to manually clear it.
  before(:each) do
    Sidekiq.options[:lifecycle_events].each_value(&:clear)
    Sidekiq::CloudWatch.configure do |c|
      c.use_mock = true
      c.aws_region_name = 'nothing'
      c.aws_access_key_id = 'key_id'
      c.aws_secret_access_key = 'secret_key'
    end
  end

  # ensure the version is up to date in both places
  describe 'VERSION' do
    it 'has an updated VERSION field' do
      spec = Gem::Specification.load('sidekiq-cloudwatch.gemspec')
      expect(Sidekiq::CloudWatch::VERSION).to eq(spec.version.to_s)
    end
  end

  describe '.enable!' do
    context 'in a sidekiq server' do
      before { allow(Sidekiq).to receive(:server?).and_return(true) }

      it 'creates a metrics publisher and installs hooks' do
        publisher = instance_double(Sidekiq::CloudWatch::Publisher)
        expect(Sidekiq::CloudWatch::Publisher).to receive(:new).and_return(publisher)

        Sidekiq::CloudWatch.enable!

        # Look, this is hard.
        expect(Sidekiq.options[:lifecycle_events][:startup]).not_to be_empty
        expect(Sidekiq.options[:lifecycle_events][:quiet]).not_to be_empty
        expect(Sidekiq.options[:lifecycle_events][:shutdown]).not_to be_empty
      end
    end

    context 'in client mode' do
      before { allow(Sidekiq).to receive(:server?).and_return(false) }

      it 'does nothing' do
        expect(Sidekiq::CloudWatch::Publisher).not_to receive(:new)

        Sidekiq::CloudWatch.enable!

        expect(Sidekiq.options[:lifecycle_events][:startup]).to be_empty
        expect(Sidekiq.options[:lifecycle_events][:quiet]).to be_empty
        expect(Sidekiq.options[:lifecycle_events][:shutdown]).to be_empty
      end
    end
  end
end
