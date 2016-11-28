def world_attrs(overrides={})
  defaults = {
    tick_index: 0,
    tick_count: 20_000,
    width: 4000,
    height: 4000,
    players: [],
    wizards: [],
    minions: [],
    projectiles: [],
    bonuses: [],
    buildings: [],
    trees: []
  }

  attrs = defaults.merge overrides

  [
    attrs[:tick_index],
    attrs[:tick_count],
    attrs[:width],
    attrs[:height],
    attrs[:players],
    attrs[:wizards],
    attrs[:minions],
    attrs[:projectiles],
    attrs[:bonuses],
    attrs[:buildings],
    attrs[:trees],
  ]
end

def wizard_attrs(overrides={})
  defaults = {
    id: 1,
    x: 400,
    y: 400,
    speed_x: 0,
    speed_y: 0,
    angle: 0, # parallel O->X
    faction: Faction::ACADEMY,
    radius: 35,
    life: 100,
    max_life: 100,
    statuses: [],
    owner_player_id: 1,
    me: true,
    mana: 100,
    max_mana: 100,
    vision_range: 600,
    cast_range: 500,
    xp: 0,
    level: 0,
    skills: [],
    remaining_action_cooldown_ticks: 0,
    remaining_cooldown_ticks_by_action: [0, 0, 0, 0, 0, 0, 0],
    master: false, 
    messages: []
  }

  attrs = defaults.merge(overrides)

  [
    attrs[:id],
    attrs[:x],
    attrs[:y],
    attrs[:speed_x],
    attrs[:speed_y],
    attrs[:angle],
    attrs[:faction],
    attrs[:radius],
    attrs[:life],
    attrs[:max_life],
    attrs[:statuses],
    attrs[:owner_player_id],
    attrs[:me],
    attrs[:mana],
    attrs[:max_mana],
    attrs[:vision_range],
    attrs[:cast_range],
    attrs[:xp],
    attrs[:level],
    attrs[:skills],
    attrs[:remaining_action_cooldown_ticks],
    attrs[:remaining_cooldown_ticks_by_action],
    attrs[:master],
    attrs[:messages],
  ]
end
