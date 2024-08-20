local ll_util = require "scripts.ll-util"

local RocketTransit = {}

function RocketTransit.register_rocket(silo, rocket, destination_name, destination)
  local rocket_inventory = rocket.get_inventory(defines.inventory.rocket)
  local rocket_inventory_size = #rocket_inventory

  local rocket_in_transit = {
    silo = silo,
    silo_name = silo.name,
    silo_position = silo.position,

    force = silo.force,

    rocket = rocket,
    inventory = game.create_inventory(rocket_inventory_size),
    rocket_launched_at = game.tick,

    destination = destination,
    destination_name = destination_name,
    destination_surface_name = ll_util.get_other_surface_name(silo.surface.name),
  }

  for i = 1, rocket_inventory_size do
    rocket_in_transit.inventory[i].transfer_stack(rocket_inventory[i])
  end

  global.rockets_in_transit[ll_util.get_rocket_unit_number(rocket)] = rocket_in_transit

  local position = silo.position
  position.y = position.y + 2.5

  local id = rendering.draw_sprite{
    sprite = 'll-rocket-bottom',
    surface = silo.surface,
    target = position,
    x_scale = 0.5,
    y_scale = 0.5,
    render_layer = "object",
  }

  game.print(position)
  game.print(id)
end

local function on_tick(event)
  for unit_number, rocket_in_transit in pairs(global.rockets_in_transit) do
    -- game.print(event.tick - rocket_in_transit.rocket_launched_at)
  end
end

RocketTransit.events = {
  [defines.events.on_tick] = on_tick,
}

function RocketTransit.on_init()
  global.rockets_in_transit = {}
end

function RocketTransit.on_configuration_changed(changed_data)
  global.rockets_in_transit = global.rockets_in_transit or {}
end

return RocketTransit
