require 'spec_helper'

describe AiBot::TrackGenerator do
  let(:generator) { AiBot::TrackGenerator.new depth: 7 }

  it 'should generate track' do
    generator.generate.take(1) do |track|
      expect(track).to be_a Array
      expect(track.size).to eq 7
    end
  end
end
