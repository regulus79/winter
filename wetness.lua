
winter.wetting_rate = 0.25
winter.drying_rate = 0.01
winter.heat_drying_multiplier = 2

winter.max_wetness = 1

-- 0 interval for normal globalstep
winter.register_timer("wetness_update", 0, function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		if core.get_item_group(core.get_node(player:get_pos()).name, "water") ~= 0 then
			local meta = player:get_meta()
			local new_wetness = math.min(meta:get_float("wetness") + winter.wetting_rate * dtime, winter.max_wetness)
			meta:set_float("wetness", new_wetness)
		end
	end
end)

winter.register_timer("drying_update", 2, function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local temp = winter.feels_like_temp(player:get_pos() + vector.new(0, 1.1, 0))
		-- If temp is greater than deadly body temp, speed up drying (kinda arbitrary but still)
		local heat_multiplier = (temp > winter.deadly_body_temperature) and winter.heat_drying_multiplier * (temp/winter.deadly_body_temperature) or 1
		local meta = player:get_meta()
		meta:set_float("wetness", math.max(0, meta:get_float("wetness") - winter.drying_rate * heat_multiplier * dtime))
	end
end)
