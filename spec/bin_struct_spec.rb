# frozen_string_literal: true

RSpec.describe BinStruct do
  it 'has a version number' do
    expect(BinStruct::VERSION).not_to be nil
  end
end
