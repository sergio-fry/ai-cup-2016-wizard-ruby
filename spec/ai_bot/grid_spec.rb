require 'spec_helper'

describe AiBot::Grid do
  let(:grid) { AiBot::Grid.build(units: units, center: center, size: size, radius: 450) }
  let(:center) { AiBot::Point.new(450, 450)}
  let(:size) { 3 }

  context 'empty' do
    let(:units) { [] }
    let(:size) { 8 }

    let(:target_grid) do
      build_grid <<-GRID
        1 1 0 0 0 0 1 1
        1 0 0 0 0 0 0 1
        0 0 0 0 0 0 0 0
        0 0 0 0 0 0 0 0
        0 0 0 0 0 0 0 0
        0 0 0 0 0 0 0 0
        1 0 0 0 0 0 0 1
        1 1 0 0 0 0 1 1
      GRID
    end

    it 'should build grid' do
      expect(grid.nodes).to eq target_grid.nodes
    end
  end

  context 'sample 1' do
    let(:units) do
      [
        Tree.new(*tree_attrs(radius: 30, x: 150, y: 450)),
      ]
    end

    let(:target_grid) do
      build_grid <<-GRID
        0 0 0
        1 0 0
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
        Tree.new(*tree_attrs(radius: 30, x: 300, y: 450)),
      ]
    end

    let(:target_grid) do
      build_grid <<-GRID
        0 0 0
        1 1 0
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
        Tree.new(*tree_attrs(radius: 30, x: 150 + delta, y: 450 + delta)),
      ]
    end

    let(:target_grid) do
      build_grid <<-GRID
        0 0 0
        1 0 0
        0 0 0
      GRID
    end

    it 'should build grid' do
      expect(grid.nodes).to eq target_grid.nodes
    end
  end
end
