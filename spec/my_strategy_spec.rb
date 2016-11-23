require 'spec_helper'
require_relative '../my_strategy'

require 'ostruct'

describe NewStrategy do
  describe 'nearest_places' do
    let(:epsilon) { 1 }
    it 'should include main points' do
      strategy = NewStrategy.new
      me = OpenStruct.new(x: 1000, y: 1000, radius: 50)
      strategy.instance_variable_set(:@me, me)

      strategy.nearest_places.each do |place|
        expect(place.distance_to(me)).to be_within(epsilon).of(50)
      end
    end
  end
end
