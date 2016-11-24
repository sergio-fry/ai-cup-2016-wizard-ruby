require 'spec_helper'
require_relative '../my_strategy'

require 'ostruct'

describe StrategyBase do
  describe 'nearest_places' do
    let(:epsilon) { 1 }
    it 'should include main points' do
      strategy = StrategyBase.new
      me = OpenStruct.new(x: 1000, y: 1000, radius: 50)
      strategy.instance_variable_set(:@me, me)

      strategy.send(:nearest_places).each do |place|
        expect(place.distance_to(me)).to be_within(epsilon).of(50)
      end
    end
  end
end

describe Router do
  it 'projection' do
    router = Router.new []

    line = Line.new(0, 0, 10, 0)
    point = Point.new(5, 5)

    projection = router.send(:projection_of_point_to_line, point, line)

    expect(projection.distance_to(Point.new(5, 0))).to be_within(0.1).of(0)
  end

  it 'projection 2' do
    router = Router.new []

    line = Line.new(0, 0, 0, 10)
    point = Point.new(5, 5)

    projection = router.send(:projection_of_point_to_line, point, line)

    expect(projection.distance_to(Point.new(0, 5))).to be_within(0.1).of(0)
  end
end

describe Line do
  it 'check inclusion' do
    line = Line.new(0, 0, 0, 10)

    point = Point.new(0, 5)
    expect(line.include?(point)).to eq true

    point = Point.new(0.5, 5)
    expect(line.include?(point)).to eq false
  end
end
