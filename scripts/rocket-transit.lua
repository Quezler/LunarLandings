local ll_util = require "scripts.ll-util"

local RocketTransit = {}

function RocketTransit.register_rocket(silo, rocket, destination_name, destination)
  local rocket_inventory = rocket.get_inventory(defines.inventory.rocket)
  local rocket_inventory_size = #rocket_inventory

  local rocket_in_transit = {
    silo = silo,
    silo_name = silo.name,
    silo_surface = silo.surface,
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
end

local function spiral_next(input)
  local x = input.x
  local y = input.y
  local output = {x = x, y = y}

  if x > y and x >= -y then
    output.y = y + 1
  elseif -y >= -x and -y > x then
    output.x = x + 1
  elseif -x > y and -x > -y then
    output.y = y - 1
  elseif y >= -x and y > x then
    output.x = x - 1
  else
    output.x = x - 1
  end

  return output
end

local function spill_rocket(surface, inventory, rocket_parts)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack and stack.valid_for_read then
      surface.spill_item_stack({0, 0}, stack, false, nil, false)
      game.print({"ll-console-info.rocket-contents-landed", "[gps=0,0," .. surface.name .. "]"})
    end
  end
  if rocket_parts and rocket_parts > 0 then
    surface.spill_item_stack({0, 0}, {name = "ll-used-rocket-part", count = rocket_parts}, false, nil, false)
  end
end


local function land_rocket(surface, inventory, landing_pad_name, rocket_parts)
  local landing_pad = ll_util.get_destination_landing_pad(landing_pad_name, surface.name)
  if not landing_pad then
    spill_rocket(surface, inventory, rocket_parts)
    return
  end
  local landing_pad_entity = landing_pad.entity
  local pad_inventory = landing_pad_entity.get_inventory(defines.inventory.chest)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack and stack.valid_for_read then
      local inserted = pad_inventory.insert(stack)
      if inserted < stack.count then
        surface.spill_item_stack(landing_pad_entity.position, {name = stack.name, count = stack.count - inserted}, false, nil, false)
      end
    end
  end
  if rocket_parts and rocket_parts > 0 and landing_pad_entity.force.technologies["ll-used-rocket-part-recycling"].researched then
    local inserted = pad_inventory.insert{name = "ll-used-rocket-part", count = rocket_parts}
    if inserted < rocket_parts then
      surface.spill_item_stack(landing_pad_entity.position, {name = "ll-used-rocket-part", count = rocket_parts - inserted}, false, nil, false)
    end
  end
end

-- fake event
local function on_rocket_launched(rocket_in_transit)
  local silo_name = rocket_in_transit.silo_name
  local force = rocket_in_transit.force
  local force_name = rocket_in_transit.force.name

  if silo_name == "rocket-silo" and force.technologies["ll-used-rocket-part-recycling"].researched then
    if rocket_in_transit.silo.valid then
      local result_inventory = rocket_in_transit.silo.get_inventory(defines.inventory.rocket_silo_result)
      result_inventory.insert{name = "ll-used-rocket-part", count = ll_util.NAUVIS_ROCKET_SILO_PARTS_REQUIRED}
    else
      -- assume neither nauvis or luna are ever deleted
      rocket_in_transit.silo_surface.spill_item_stack(rocket_in_transit.silo_position, {name = "ll-used-rocket-part", count = ll_util.NAUVIS_ROCKET_SILO_PARTS_REQUIRED}, false, nil, false)
    end
  end

  local destination_name = rocket_in_transit.destination_name

  if destination_name == "Space" then
    if rocket_in_transit.inventory.get_item_count("satellite") >= 1 then
      if rocket_in_transit.silo_name == "rocket-silo" then
        local satellites_launched = global.satellites_launched[force_name] or 0
        if satellites_launched == 0 then
          if game.is_multiplayer() then
            game.print({"ll-console-info.first-satellite-launched"})
          else
            game.show_message_dialog{text = {"ll-console-info.first-satellite-launched"}}
          end
          game.print({"ll-console-info.first-satellite-launched-urq-hint"})
          game.print({"ll-console-info.new-destination-unlocked"})
          force.technologies["ll-luna-exploration"].enabled = true
        end
        global.satellites_launched[force_name] = satellites_launched + 1
        if satellites_launched > 0 then
          local position = global.satellite_cursors[force_name] or {x = 0, y = 0}
          for i = 1, 300 do
            while force.is_chunk_charted("luna", position) do
              position = spiral_next(position)
            end
            force.chart("luna", {
              {
                x = position.x * 32,
                y = position.y * 32
              },
              {
                x = (position.x + 0.5) * 32,
                y = (position.y + 0.5) * 32
              }
            })
            position = spiral_next(position)
            global.satellite_cursors[force_name] = position
          end
        end
      end
    end
  elseif destination_name == "Nauvis Surface" or destination_name == "Luna Surface" then
    local surface = game.get_surface(rocket_in_transit.destination_surface_name)
    spill_rocket(surface, rocket_in_transit.inventory, silo_name == "ll-rocket-silo-down" and ll_util.LUNA_ROCKET_SILO_PARTS_REQUIRED or 0)
  else
    local surface = game.get_surface(rocket_in_transit.destination_surface_name)
    land_rocket(surface, rocket_in_transit.inventory, destination_name, silo_name == "ll-rocket-silo-down" and ll_util.LUNA_ROCKET_SILO_PARTS_REQUIRED or 0)
  end
end

local function on_tick(event)
  for unit_number, rocket_in_transit in pairs(global.rockets_in_transit) do
    local ticks_since_launch = event.tick - rocket_in_transit.rocket_launched_at

    -- copied from here, manually watched start to finish to ensure no 1 tick diff in either direction:
    -- https://github.com/Quezler/glutenfree/blob/main/mods/glutenfree-rocket-silo-events/control.lua
    -- log(ticks_since_launch .. ' ' .. rocket_in_transit.silo.rocket_silo_status)

    -- [1]    = 14, -- defines.rocket_silo_status.launch_started
    -- [121]  =  9, -- defines.rocket_silo_status.engine_starting
    -- [451]  = 10, -- defines.rocket_silo_status.arms_retract
    -- [555]  = 11, -- defines.rocket_silo_status.rocket_flying
    -- [1095] = 12, -- defines.rocket_silo_status.lights_blinking_close
    -- [1162] = event, on_rocket_launched
    -- [1276] = 13, -- defines.rocket_silo_status.doors_closing
    -- [1532] =  0, -- defines.rocket_silo_status.building_rocket

    if ticks_since_launch == 1162 then
      on_rocket_launched(rocket_in_transit)
    end

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
