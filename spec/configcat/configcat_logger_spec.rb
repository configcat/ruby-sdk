require 'spec_helper'

RSpec.describe ConfigCat::ConfigCatLogger do
  let(:logger) { double("logger") }
  let(:configcat_logger) { described_class.new(nil) }

  describe ".mask_sdk_key" do
    [
      ["", ""],
      ["abc123", "abc123"],
      ["/abc123", "/abc123"],
      ["abc/123", "*bc/123"],
      ["abc123/", "*bc123/"],
      ["configcat-sdk-1/TEST_KEY-0123456789012/1234567890123456789012", "***************/**********************/****************789012"]
    ].each do |sdk_key, expected_masked_sdk_key|
      it "masks '#{sdk_key}' as '#{expected_masked_sdk_key}'" do
        expect(described_class.mask_sdk_key(sdk_key)).to eq(expected_masked_sdk_key)
      end
    end
  end

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
