require 'spec_helper'

RSpec.describe Sidekiq::CloudWatch::Configuration do
  subject { described_class.new }

  describe '#new' do
    it { is_expected.to be }

    specify { expect(subject.leader).to be(true) }
    specify { expect(subject.use_mock).to be(false) }
    specify { expect(subject.ready?).to be(false) }

    context 'when AWS settings set' do
      before(:each) do
        subject.aws_region_name = 'us-east-1'
        subject.aws_access_key_id = 'access-key'
        subject.aws_secret_access_key = 'secret-key'
      end
      specify { expect(subject.ready?).to be(true) }
    end
  end
end
