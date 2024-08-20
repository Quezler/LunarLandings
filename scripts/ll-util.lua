local ll_util = {}

ll_util.NAUVIS_ROCKET_SILO_PARTS_REQUIRED = 20
ll_util.LUNA_ROCKET_SILO_PARTS_REQUIRED = 5

function ll_util.get_other_surface_name(surface_name)
  return surface_name == "nauvis" and "luna" or "nauvis"
end

function ll_util.inventory_count_non_empty_stacks(inventory)
  return #inventory - inventory.count_empty_stacks(true, true)
end

return ll_util
