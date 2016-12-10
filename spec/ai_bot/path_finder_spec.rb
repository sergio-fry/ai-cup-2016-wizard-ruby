require 'spec_helper'

describe AiBot::PathFinder do
  let(:path_finder) { AiBot::PathFinder.new grid: grid }

  describe 'found path' do
    subject { path_finder.find(from: from_point, to: to_point).map { |node| [node.x, node.y] } }
    let(:from_point) { grid.node_at(*from) }
    let(:to_point) { grid.node_at(*to) }

    context 'when map is empty' do
      let(:grid) do
        build_grid <<-GRID
          0 0 0
          0 0 0
          0 0 0
        GRID
      end

      let(:from) { [0, 1] }
      let(:to) { [2, 1] }

      it { is_expected.to eq [[0, 1], [1, 1], [2, 1]] }
    end

    context do
      let(:grid) do
        build_grid <<-GRID
          0 1 0
          0 1 0
          0 0 0
        GRID
      end

      let(:from) { [0, 1] }
      let(:to) { [2, 1] }

      it { is_expected.to eq [[0, 1], [0, 2], [1, 2], [2, 2], [2, 1]] }
    end
  end

  it 'should not fail if from is filled'
end
