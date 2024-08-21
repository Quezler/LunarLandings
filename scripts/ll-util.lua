local ll_util = {}

ll_util.NAUVIS_ROCKET_SILO_PARTS_REQUIRED = 20
ll_util.LUNA_ROCKET_SILO_PARTS_REQUIRED = 5

function ll_util.get_other_surface_name(surface_name)
  return surface_name == "nauvis" and "luna" or "nauvis"
end

function ll_util.inventory_count_non_empty_stacks(inventory)
  return #inventory - inventory.count_empty_stacks(true, true)
end

function ll_util.get_rocket_unit_number(rocket)
  return script.register_on_entity_destroyed(rocket)
end

function ll_util.get_destination_landing_pad(landing_pad_name, landing_pad_surface_name)
  local landing_pads = global.landing_pad_names[landing_pad_surface_name][landing_pad_name]
  if not landing_pads then return end

  local landing_pad_unit_number, _ = next(landing_pads)
  local landing_pad = global.landing_pads[landing_pad_unit_number]
  if not (landing_pad and landing_pad.entity.valid) then
    return
  end
  if landing_pad.last_targeted_at == game.tick then
    return
  end
  return landing_pad
end

return ll_util
