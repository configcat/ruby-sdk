require 'spec_helper'

RSpec.describe ConfigCat::ConfigCatLogger do
  let(:logger) { double("logger") }
  let(:configcat_logger) { described_class.new(nil) }

  before do
    allow(ConfigCat).to receive(:logger).and_return(logger)
  end

  describe "#enabled_for?" do
    it "works when logger level returns an integer" do
      allow(logger).to receive(:level).and_return(2)
      expect(configcat_logger.enabled_for?(::Logger::Severity::WARN)).to eq true
    end

    it "works when logger level returns a symbol" do
      allow(logger).to receive(:level).and_return(:warn)
      expect(configcat_logger.enabled_for?(::Logger::Severity::WARN)).to eq true
    end
  end
end
