

winter.head_conductivity_weight = 0.10
winter.torso_conductivity_weight = 0.50
winter.legs_conductivity_weight = 0.30
winter.feet_conductivity_weight = 0.10


winter.get_clothing = function() return {} end

if not core.get_modpath("3d_armor") then
	return
end


winter.get_clothing = function(player)
	local clothing = {}
	local _, armor_inv = armor:get_valid_player(player, "winter")
	for _, stack in pairs(armor_inv:get_list("armor")) do
		local def = stack:get_definition()
		if def and def.groups and def.groups.clothing and def.groups.thermal_conductivity then
			table.insert(clothing, def.groups)
		end
	end
	return clothing
end


winter.get_clothing_group_conductivity = function(clothing, group)
	-- Using resistance = 1/conductivity so that it's easier to work with
	-- Assuming the first layer of clothing is skin
	local resistance = 1 / winter.default_body_thermal_conductivity
	for _, clothing_groups in pairs(clothing) do
		if clothing_groups[group] then
			resistance = resistance + 1 / clothing_groups.thermal_conductivity
		end
	end
	return 1 / resistance
end


core.register_on_mods_loaded(function()
	armor:register_armor(":winter:hat", {
		description = "Hat",
		inventory_image = "default_dirt.png",
		groups = {armor_head = 1, armor_use = 2000, clothing = 1, thermal_conductivity = 2.5}
	})
	armor:register_armor(":winter:coat", {
		description = "Coat",
		inventory_image = "default_snow.png",
		groups = {armor_torso = 1, armor_use = 2000, clothing = 1, thermal_conductivity = 2.5}
	})
	armor:register_armor(":winter:pants", {
		description = "Pants",
		inventory_image = "default_stone.png",
		groups = {armor_legs = 1, armor_use = 2000, clothing = 1, thermal_conductivity = 2.5}
	})
	armor:register_armor(":winter:boots", {
		description = "Boots",
		inventory_image = "default_cobble.png",
		groups = {armor_feet = 1, armor_use = 2000, clothing = 1, thermal_conductivity = 2.5}
	})
end)