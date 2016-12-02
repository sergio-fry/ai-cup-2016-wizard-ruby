require 'spec_helper'

describe AiBot::WorldState do
  let(:me) do
    Wizard.new(*wizard_attrs(angle: 0)).extend(AiBot::Unit)
  end

  let(:units) { [tree, wizard] }

  let(:world) do
    AiBot::WorldState.new(units: units, game: game)
  end

  let(:game) { Game.new(*game_attrs) }

  let(:epsilon) { 0.01 }
  let(:tree) { Tree.new(*tree_attrs) }
  let(:wizard) { Wizard.new(*wizard_attrs) }

  context do
    before do
      wizard.x = 100
      wizard.y = 100
      wizard.speed_x = 2
      wizard.speed_y = 1
    end

    it 'should update position' do
      wizard1 = world.next.unit_by_id wizard.id

      expect(wizard1.x).to eq 102
      expect(wizard1.y).to eq 101
    end
  end

  it 'should update position when turned and moved' do
    me.angle = -1.5707963267948966
    me.x = 100
    me.y = 3700

    move = Move.new
    move.speed = 1
    move.turn = 0.1

    world1 = world.next
    me1 = me.clone
    world1.apply_move(me1, move)

    expect(me1.x).to eq (100)
    expect(me1.y).to eq (3699)

    move = Move.new
    move.speed = 1

    world2 = world1.next
    me2 = me1.clone
    world2.apply_move(me2, move)

    expect(me2.x).to be_within(epsilon).of(100.1)
    expect(me2.y).to be_within(epsilon).of(3698.005)
    expect(me2.speed_x).to be_within(epsilon).of(0.0998334166468311)
    expect(me2.speed_y).to be_within(epsilon).of(-0.9950041652778054)
    expect(me2.angle).to be_within(epsilon).of(-1.4707963267948965)

    move = Move.new
    move.speed = 1

    world3 = world2.next
    me3 = me2.clone
    world3.apply_move(me3, move)

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

    world.units = [tree]

    move = Move.new
    move.speed = 1

    world.apply_move(me, move)

    expect(me.distance_to_unit(tree) >= (me.radius + tree.radius)).to eq true
  end

  it 'should limit turn angle' do
    me.angle = 0

    move = Move.new
    move.turn = Math::PI / 2

    world.apply_move(me, move)

    expect(me.angle.abs > 0).to eq true
    expect(me.angle.abs < 0.105).to eq true
  end

  it 'should use strafe' do
    me.angle = 0
    me.x = 400
    me.y = 400

    move = Move.new
    move.strafe_speed = 3

    world.apply_move(me, move)

    expect(me.x).to eq 400
    expect(me.y).to eq 403
  end

  it 'should use strafe' do
    me.angle = -1.5707963267948965
    me.x = 100
    me.y = 3700

    move = Move.new
    move.turn = 0.1
    move.speed = 2
    move.strafe_speed = 1

    world.apply_move(me, move)

    expect(me.x).to eq 101
    expect(me.y).to eq 3698
  end

  it 'should limit speed' do
    me.angle = -1.5707963267948965
    me.x = 100
    me.y = 3700

    move = Move.new
    move.turn = 0.1
    move.speed = 3
    move.strafe_speed = 3

    world.apply_move(me, move)

    expect(me.x).to eq 102.4
    expect(me.y).to eq 3697.6
  end
end
