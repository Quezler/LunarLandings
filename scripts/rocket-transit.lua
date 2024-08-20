local RocketTransit = {}

-- destination is the preferred/preselected destination, will fallback to destination_name if inelligable
function RocketTransit.launch_rocket(silo, destination_name, destination)
  if destination then assert(destination.entity) end -- entry of global.landing_pads

  local launched = silo.launch_rocket()
  if launched == false then error("'defines.rocket_silo_status.rocket_ready' wasn't checked.") end -- sanity check

  global.rocket_silo_destination[silo.unit_number] = {
    tick = game.tick, -- entries older than 0-1 ticks are considered stale
    silo = silo,
    destination = destination,
    destination_name = destination_name,
  }

end

function RocketTransit.get_rocket_silo_destination(silo)
  local rocket_silo_destination = global.rocket_silo_destination[silo.unit_number]
  assert(rocket_silo_destination)
  return rocket_silo_destination
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
  global.rocket_silo_destination = {}
end

function RocketTransit.on_configuration_changed(changed_data)
  global.rockets_in_transit = global.rockets_in_transit or {}
  global.rocket_silo_destination = global.rocket_silo_destination or {}
end

return RocketTransit
