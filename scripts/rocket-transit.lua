local ll_util = require "scripts.ll-util"

local RocketTransit = {}

function RocketTransit.register_rocket(silo, rocket, destination_name, destination)
  local rocket_in_transit = {
    silo = silo,
    silo_name = silo.name,
    silo_position = silo.silo_position,

    rocket = rocket,
    rocket_inventory = nil,
    rocket_launched_at = game.tick,

    destination = destination,
    destination_name = destination_name,
    destination_surface_name = ll_util.get_other_surface_name(silo.surface.name),
  }

  local rocket_inventory = rocket.get_inventory(defines.inventory.rocket)

  local rocket_parts = (rocket_in_transit.silo_name == "ll-rocket-silo-down" and ll_util.LUNA_ROCKET_SILO_PARTS_REQUIRED or 0)
  local inventory_size_required = ll_util.inventory_count_non_empty_stacks(rocket_inventory)

  rocket_in_transit.rocket_inventory = game.create_inventory(ll_util)

  global.rockets_in_transit[rocket.unit_number] = rocket_in_transit
end

function RocketTransit.create_rocket(destination, rocket_inventory)
  local transit_inventory = game.create_inventory(25)  -- Rocket inventory size + rocket parts
  for i = 1, 25 do
    transit_inventory[i].transfer_stack(rocket_inventory[i])
  end
  local transit_data = {
    destination = destination,
    rocket_inventory = rocket_inventory,
  }
end

function RocketTransit.on_init()
  global.rockets_in_transit = {}
end

function RocketTransit.on_configuration_changed(changed_data)
  global.rockets_in_transit = global.rockets_in_transit or {}
end

return RocketTransit
