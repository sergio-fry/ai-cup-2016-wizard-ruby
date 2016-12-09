require 'spec_helper'

class Grid
  def initialize
    @nodes = []
  end

  def node_at(x, y)
    @nodes.dig(x, y)
  end

  def add_node(x, y)
    @nodes[x] ||= []
    @nodes[x][y] = AiBot::Point.new(x, y)
  end
end

def build_grid(input)

  new_grid = Grid.new

  input.split("\n").each_with_index do |line, y|
    line.split.each_with_index do |node, x|
      new_grid.add_node(x, y) if node == '0'
    end
  end

end

describe AiBot::PathFinder do
  let(:path_finder) { AiBot::PathFinder.new grid: grid }

  describe 'found path' do
    subject { path_finder.find(from: from_point, to: to_point).map { |p| [p.x, p.y] } }
    let(:from_point) { AiBot::Point.new(from[0], from[1]) }
    let(:to_point) { AiBot::Point.new(to[0], to[1]) }

    context 'when map is empty' do
      let(:grid) do
        build_grid <<-GRID
          0 0 0
          0 0 0
          0 0 0
        GRID
      end

      let(:from) { [1, 1] }
      let(:to) { [1, 2] }

      it { is_expected.to eq [[1, 1], [1, 2]]}
    end
  end
end
