require 'spec_helper'

describe AiBot::Utils do
  describe '#normalize_angle' do
    it 'normalize' do
      expect(AiBot::Utils.normalize_angle(0.5 * Math::PI)).to eq (0.5 * Math::PI)
      expect(AiBot::Utils.normalize_angle(1.5 * Math::PI)).to eq (-0.5 * Math::PI)
      expect(AiBot::Utils.normalize_angle(-1.5 * Math::PI)).to eq (0.5 * Math::PI)
    end
  end
end
