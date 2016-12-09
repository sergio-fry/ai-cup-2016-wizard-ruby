require 'spec_helper'

describe AiBot::Grid do
  let(:grid) { AiBot::Grid.build(units: units, center: center, size: 3, radius: 450) }
  let(:center) { AiBot::Point.new(450, 450)}

  context 'sample 1' do
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

  context 'sample 2' do
    let(:units) do
      [
        Tree.new(*tree_attrs(radius: 30, x: 300, y: 30)),
      ]
    end

    let(:target_grid) do
      build_grid <<-GRID
        1 1 0
        0 0 0
        0 0 0
      GRID
    end

    it 'should build grid' do
      expect(grid.nodes).to eq target_grid.nodes
    end
  end

  context 'sample 3' do
    let(:delta) { 1000 }
    let(:center) { AiBot::Point.new(450 + delta, 450 + delta)}

    let(:units) do
      [
        Tree.new(*tree_attrs(radius: 30, x: 30 + delta, y: 30 + delta)),
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
end
