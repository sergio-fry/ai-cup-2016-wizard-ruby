require 'spec_helper'

describe AiBot::Grid do
  let(:grid) { AiBot::Grid.build(units: units, center: center, size: 3, radius: 450) }
  let(:center) { AiBot::Point.new(450, 450)}

  let(:units) do
    [
      Tree.new(*tree_attrs(radius: 30, x: 30, y: 30)),
    ]
  end

  it 'should build grid' do
    expect(grid.node_at(0, 0)).to eq nil # filled by tree
    expect(grid.node_at(0, 1)).to be_a AiBot::Point
    expect(grid.node_at(0, 2)).to be_a AiBot::Point
    expect(grid.node_at(1, 0)).to be_a AiBot::Point
    expect(grid.node_at(1, 1)).to be_a AiBot::Point
    expect(grid.node_at(1, 2)).to be_a AiBot::Point
    expect(grid.node_at(2, 0)).to be_a AiBot::Point
    expect(grid.node_at(2, 1)).to be_a AiBot::Point
    expect(grid.node_at(2, 2)).to be_a AiBot::Point
  end
end
