require 'spec_helper'

require 'datadog/tracing/distributed/helpers'
require 'datadog/tracing/utils'

RSpec.describe Datadog::Tracing::Distributed::Helpers do
  describe '#clamp_sampling_priority' do
    subject(:sampling_priority) { described_class.clamp_sampling_priority(value) }

    [
      [-1, 0],
      [0, 0],
      [1, 1],
      [2, 1]
    ].each do |value, expected|
      context "with input of #{value}" do
        let(:value) { value }

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#format_base16_number' do
    subject(:number) { described_class.format_base16_number(value) }

    [
      %w[1 1],

      # Test removing leading zeros
      %w[0 0],
      %w[000000 0],
      %w[000001 1],
      %w[000010 10],

      # Test lowercase
      %w[DEADBEEF deadbeef],

      # # Test at boundary (64-bit)
      # [(1 << 64).to_s(16), '1' + '0' * 16],
      # [((1 << 64) - 1).to_s(16), 'f' * 16],

      # # Test at boundary (128-bit)
      # [(1 << 128).to_s(16), '1' + '0' * 32],
      # [((1 << 128) - 1).to_s(16), 'f' * 32],
    ].each do |value, expected|
      context "with input of #{value}" do
        let(:value) { value }

        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#value_to_id' do
    context 'when value is not present' do
      subject(:subject) { described_class.value_to_id(nil) }

      it { is_expected.to be_nil }
    end

    context 'when value is' do
      [
        [nil, nil],
        ['not a number', nil],
        ['1 2', nil], # "1 2".to_i => 1, but it's an invalid format
        ['0', nil],
        ['', nil],

        # Larger than we allow
        [(Datadog::Tracing::Utils::EXTERNAL_MAX_ID + 1).to_s, nil],

        # Negative number
        ['-100', -100 + (2**64)],

        # Allowed values
        [Datadog::Tracing::Utils::RUBY_MAX_ID.to_s, Datadog::Tracing::Utils::RUBY_MAX_ID],
        [Datadog::Tracing::Utils::EXTERNAL_MAX_ID.to_s, Datadog::Tracing::Utils::EXTERNAL_MAX_ID],
        ['1', 1],
        ['123456789', 123456789]
      ].each do |value, expected|
        context value.inspect do
          it { expect(described_class.value_to_id(value)).to eq(expected) }
        end
      end

      # Base 16
      [
        # Larger than we allow
        # DEV: We truncate to 64-bit for base16
        [(Datadog::Tracing::Utils::EXTERNAL_MAX_ID + 1).to_s(16), 1],
        [Datadog::Tracing::Utils::EXTERNAL_MAX_ID.to_s(16), nil],

        [Datadog::Tracing::Utils::RUBY_MAX_ID.to_s(16), Datadog::Tracing::Utils::RUBY_MAX_ID],
        [(Datadog::Tracing::Utils::EXTERNAL_MAX_ID - 1).to_s(16), Datadog::Tracing::Utils::EXTERNAL_MAX_ID - 1],

        ['3e8', 1000],
        ['3E8', 1000],
        ['10000', 65536],
        ['deadbeef', 3735928559],
      ].each do |value, expected|
        context value.inspect do
          it { expect(described_class.value_to_id(value, base: 16)).to eq(expected) }
        end
      end
    end
  end

  describe '#value_to_number' do
    context 'when value is ' do
      [
        [nil, nil],
        ['not a number', nil],
        ['1 2', nil], # "1 2".to_i => 1, but it's an invalid format
        ['', nil],

        # Sampling priorities
        ['-1', -1],
        ['0', 0],
        ['1', 1],
        ['2', 2],

        # Allowed values
        [Datadog::Tracing::Utils::RUBY_MAX_ID.to_s, Datadog::Tracing::Utils::RUBY_MAX_ID],
        [(Datadog::Tracing::Utils::RUBY_MAX_ID + 1).to_s, Datadog::Tracing::Utils::RUBY_MAX_ID + 1],
        [Datadog::Tracing::Utils::TraceId::MAX.to_s, Datadog::Tracing::Utils::TraceId::MAX],
        [(Datadog::Tracing::Utils::TraceId::MAX + 1).to_s, Datadog::Tracing::Utils::TraceId::MAX + 1],
        ['-100', -100],
        ['100', 100],
      ].each do |value, expected|
        context value.inspect do
          subject(:subject) { described_class.value_to_number(value) }

          it { is_expected.to be == expected }
        end
      end

      # Base 16
      [
        # Larger than we allow
        [Datadog::Tracing::Utils::TraceId::MAX.to_s(16), Datadog::Tracing::Utils::TraceId::MAX],
        [(Datadog::Tracing::Utils::TraceId::MAX + 1).to_s(16), Datadog::Tracing::Utils::TraceId::MAX + 1],

        [Datadog::Tracing::Utils::RUBY_MAX_ID.to_s(16), Datadog::Tracing::Utils::RUBY_MAX_ID],
        [(Datadog::Tracing::Utils::RUBY_MAX_ID + 1).to_s(16), Datadog::Tracing::Utils::RUBY_MAX_ID + 1],

        ['3e8', 1000],
        ['3E8', 1000],
        ['deadbeef', 3735928559],
        ['10000', 65536],

        ['invalid-base16', nil]
      ].each do |value, expected|
        context value.inspect do
          subject(:subject) { described_class.value_to_number(value, base: 16) }

          it { is_expected.to be == expected }
        end
      end
    end
  end
end
