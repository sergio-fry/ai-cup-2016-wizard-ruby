require 'spec_helper'

describe AiBot::GridMapper do
  let(:grid_mapper) { AiBot::GridMapper.new(center: center, size: 3, radius: 450) }
  let(:center) { AiBot::Point.new(450, 450)}

  describe '#to_grid' do
    subject { grid_mapper.to_grid(*coords)}
    let(:coords) { [150, 150] }
    it { is_expected.to eq [0, 0] }
  end

  describe '#from_grid' do
    subject { grid_mapper.from_grid(*coords)}
    let(:coords) { [0, 0] }
    it { is_expected.to eq [150, 150] }
  end
end
