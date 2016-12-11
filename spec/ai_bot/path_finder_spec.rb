require 'spec_helper'

describe AiBot::PathFinder do
  let(:path_finder) { AiBot::PathFinder.new grid: grid }

  describe 'found path' do
    subject { path_finder.find(from: from, to: to).map { |node| [node.x, node.y] } }

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

    context 'when start is filled' do
      let(:grid) do
        build_grid <<-GRID
          0 0 0
          1 0 0
          0 0 0
        GRID
      end

      let(:from) { [0, 1] }
      let(:to) { [2, 1] }

      it { is_expected.to eq [[0, 1], [1, 1], [2, 1]] }
    end

    context 'when end is filled' do
      let(:grid) do
        build_grid <<-GRID
          0 0 0
          0 0 1
          0 0 0
        GRID
      end

      let(:from) { [0, 1] }
      let(:to) { [2, 1] }

      it { is_expected.to eq [[0, 1], [1, 1], [2, 1]] }
    end
  end
end
