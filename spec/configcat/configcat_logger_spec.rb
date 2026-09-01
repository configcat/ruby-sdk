require 'spec_helper'

RSpec.describe ConfigCat::ConfigCatLogger do
  let(:subject) { described_class.new(nil) }

  before do
    ConfigCat.logger = subject
  end

  describe "#enabled_for?" do
    it "works when logger level returns an integer" do
      allow(subject).to receive(:level).and_return(2)
      expect(subject.enabled_for?(::Logger::Severity::WARN)).to eq true
    end

    it "works when logger level returns a symbol" do
      allow(subject).to receive(:level).and_return(:warn)
      expect(subject.enabled_for?(::Logger::Severity::WARN)).to eq true
    end
  end
end
