require 'spec_helper'

describe 'Find path at start' do
  let(:grid) { AiBot::Grid.build(units: units, center: center, size: 15, radius: 600) }
  let(:center) { AiBot::Point.new(100, 3700)}

  let(:units) do
    [
      [300.0, 3900.0, 35.0],
      [300.0, 3800.0, 35.0],
      [200.0, 3800.0, 35.0],
      [100.0, 3700.0, 35.0],
      [200.0, 3700.0, 35.0],
      [902.6130586671778, 2768.0976194514765, 50.0],
      [2312.1259974228437, 3950.0, 50.0],
      [1370.6603203516029, 3650.0, 50.0],
      [350.0, 1656.7486446626867, 50.0],
      [50.0, 2693.2577778083373, 50.0],
      [1929.2893218813454, 2400.0, 50.0],
      [400.0, 3600.0, 100.0],
    ].map do |x, y, radius|
      Tree.new(*tree_attrs(radius: radius, x: x, y: x))
    end

    []
  end

  it 'should find a path' do
    path_finder = AiBot::PathFinder.new grid: grid
    path = path_finder.find(from: [6, 6], to: [7, 6])
  end
end
