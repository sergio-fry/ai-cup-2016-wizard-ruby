require 'spec_helper'

class Grid
  def initialize
    @nodes = {}
  end

  def node_at(x, y)
    @nodes.dig(x.to_i, y.to_i)
  end

  def add_node(node)
    @nodes[node.x.to_i] ||= {}
    @nodes[node.x.to_i][node.y.to_i] = node
  end

  def neighbors_for(node)
    [
      node_at(node.x - 1, node.y),
      node_at(node.x, node.y - 1),
      node_at(node.x + 1, node.y),
      node_at(node.x, node.y + 1)
    ].compact
  end
end

def build_grid(input)
  new_grid = Grid.new

  input.split("\n").each_with_index do |line, y|
    line.split.each_with_index do |node, x|
      new_grid.add_node AiBot::Point.new(x, y) if node == '0'
    end
  end

  new_grid
end

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
end
