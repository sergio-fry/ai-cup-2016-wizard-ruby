require 'spec_helper'

describe AiBot::World do
  subject(:world) { AiBot::World.new(me, world_obj, game) }
  let(:me) { Wizard.new(*wizard_attrs(angle: 0)) }
  let(:world_obj) { World.new(*world_attrs(wizards: [me])) }
  let(:game) { Game.new *([nil]*111) }

  it 'should return me' do
    expect(world.me).not_to be_nil
  end

  it 'should calculate wizard movement' do
    x, y = me.x, me.y

    move = Move.new
    move.speed = 4

    world.tick! move

    x1 = world.me.x
    y1 = world.me.y

    expect(x1).to eq (x+4)
    expect(y1).to eq y
  end
end
