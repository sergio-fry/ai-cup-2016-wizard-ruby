require 'spec_helper'

describe AiBot::Grid do
  let(:grid) { AiBot::Grid.build(units: units, center: center, size: 3, radius: 450) }
  let(:center) { AiBot::Point.new(450, 450)}

  let(:units) do
    [
      Tree.new(*tree_attrs(radius: 30, x: 30, y: 30)),
    ]
  end

  let(:target_grid) do
    build_grid <<-GRID
      1 0 0
      0 0 0
      0 0 0
    GRID
  end

  it 'should build grid' do
    expect(grid.nodes).to eq target_grid.nodes
  end
end
