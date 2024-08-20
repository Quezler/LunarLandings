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
end

local function on_rocket_launched_to_space()
end

local function on_rocket_launched_to_surface()
end

local function on_rocket_launched_to_landing_pad()
end

local function on_rocket_launched(rocket_in_transit)
  local silo_name = rocket_in_transit.silo_name
  local force = rocket_in_transit.force

  if silo_name == "rocket-silo" and force.technologies["ll-used-rocket-part-recycling"].researched then
    -- TODO: if solo still valid, put the used parts in there, else drop on ground
    -- local result_inventory = silo.get_inventory(defines.inventory.rocket_silo_result)
    -- result_inventory.insert{name = "ll-used-rocket-part", count = ll_util.NAUVIS_ROCKET_SILO_PARTS_REQUIRED}
  elseif silo_name == "ll-rocket-silo-interstellar" then
    -- Win the game
    if game.finished or game.finished_but_continuing or global.finished then return end
    global.finished = true
    if remote.interfaces["better-victory-screen"] and remote.interfaces["better-victory-screen"]["trigger_victory"] then
      remote.call("better-victory-screen", "trigger_victory", force)
    else
      game.set_game_state{
        game_finished = true,
        player_won = true,
        can_continue = true,
        victorious_force = force
      }
    end
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
