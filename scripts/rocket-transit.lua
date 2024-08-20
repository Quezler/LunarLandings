local RocketSilo = {}

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

function RocketTransit

function RocketTransit.on_init()
  global.rockets_in_transit = {}
end

function RocketTransit.on_configuration_changed(changed_data)
  global.rockets_in_transit = global.rockets_in_transit or {}
end

return RocketTransit
