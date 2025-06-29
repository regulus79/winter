

winter.wind_force = 1.5


winter.register_timer("physics_override", 0.25, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		-- Slower movement when cold
		local body_temp = player:get_meta():get_float("body_temperature")
		if body_temp < winter.chilly_body_temperature then
			local multiplier = math.max(0.15, math.min(1, 10 / (winter.chilly_body_temperature - body_temp) * (math.random(75,125)/100)))
			player:set_physics_override({
				speed_walk = multiplier,
				jump = math.max(0.75, multiplier),
			})
		else
			player:set_physics_override({
				speed_walk = 1,
				jump = 1
			})
		end
	end
end)

winter.register_timer("wind_force", 0, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local wind = winter.wind(player:get_pos())
		if wind:length() > 8 then
			local wind_shelter_ratio = 1 - winter.get_cached(player, "wind_sheltered")
			local player_vel_along_wind = (player:get_velocity() / wind:length()):dot(wind:normalize())
			local wind_accel = wind * wind_shelter_ratio * winter.wind_force * (1 - player_vel_along_wind)
			player:add_velocity(wind_accel * dtime)
		end
	end
end)
