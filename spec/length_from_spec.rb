# frozen_string_literal: true

require_relative 'spec_helper'

module BinStruct
  RSpec.describe LengthFrom do
    it 'accepts a proc length_from' do
      s = String.new(length_from: -> { 5 } )
      s.read('aaaaaaaaaaaaaaa')
      expect(s.sz).to eq(5)
    end
  end
end
