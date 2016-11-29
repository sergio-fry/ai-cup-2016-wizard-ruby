require 'spec_helper'

describe AiBot::World do
  let(:me) do
    Wizard.new(*wizard_attrs(angle: 0)).extend(AiBot::Unit)
  end

  let(:world) do
    w = World.new(*world_attrs(wizards: [me]))

    AiBot::World.init_from w
  end

  let(:game) { Game.new *([nil]*111) }
  let(:epsilon) { 0.01 }
  let(:tree) { Tree.new(*tree_attrs).extend(AiBot::Unit) }

  it 'should update position when turned and moved' do
    me.angle = -1.5707963267948966
    me.x = 100
    me.y = 3700

    move = Move.new
    move.speed = 1
    move.turn = 0.1

    world.tick!({ me.id => move })

    me1 = world.unit_by_id(me.id)

    expect(me1.x).to eq (100)
    expect(me1.y).to eq (3699)

    move = Move.new
    move.speed = 1

    world.tick!({ me.id => move })

    me2 = world.unit_by_id(me.id)
    expect(me2.x).to be_within(epsilon).of(100.1)
    expect(me2.y).to be_within(epsilon).of(3698.005)
    expect(me2.speed_x).to be_within(epsilon).of(0.0998334166468311)
    expect(me2.speed_y).to be_within(epsilon).of(-0.9950041652778054)
    expect(me2.angle).to be_within(epsilon).of(-1.4707963267948965)

    move = Move.new
    move.speed = 1

    world.tick!({ me.id => move })

    me3 = world.unit_by_id(me.id)
    expect(me3.x).to be_within(epsilon).of(100.2)
    expect(me3.y).to be_within(epsilon).of(3697.01)
    expect(me3.speed_x).to be_within(epsilon).of(0.0998334166468311)
    expect(me3.speed_y).to be_within(epsilon).of(-0.9950041652778054)
    expect(me3.angle).to be_within(epsilon).of(-1.4707963267948965)
  end

  it 'should not allow collisions' do
    me.angle = 0
    me.x = 400
    me.y = 400

    tree.x = me.x + me.radius + tree.radius
    tree.y = me.y

    world.trees = [tree]

    move = Move.new
    move.speed = 1

    world.tick!({ me.id => move })

    me1 = world.unit_by_id me.id
    tree1 = world.unit_by_id tree.id

    expect(me1.distance_to_unit(tree)).to >= (me.radius + tree.radius)
  end
end
