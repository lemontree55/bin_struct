# frozen_string_literal: true

require_relative 'spec_helper'

module BinStructStrutableSpec
  class Test
    include BinStruct::Structable
  end
end

module BinStruct
  RSpec.describe Structable do
    let(:instance) { BinStructStrutableSpec::Test.new }

    describe '#type_name' do
      it 'gives type name as a String' do
        expect(instance.type_name).to eq('Test')
      end
    end

    describe '#to_s' do
      it 'calls super' do
        expect(instance.to_s).to match('#<BinStructStrutableSpec::Test.*>')
      end
    end

    describe '#sz' do
      it 'returns size of #to_s' do
        expect(instance.sz).to eq(50)
      end
    end

    describe '#to_human' do
      it 'calls super' do
        expect { instance.to_human }.to raise_error(NoMethodError, /no superclass method/)
      end
    end
  end
end