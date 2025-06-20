

winter.wind_force = 1.5


-- Keep a cache of the shelter ratios since they require raycasts which might be slow?
local wind_shelter_cache = {}
local cache_update_timer = 0
local cache_update_interval = 1

local physics_update_timer = 0
local physics_update_interval = 0.25

core.register_globalstep(function(dtime)
	cache_update_timer = cache_update_timer + dtime
	if cache_update_timer > cache_update_interval then
		cache_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			_, wind_shelter_cache[player:get_player_name()] = winter.sheltered(player:get_pos() + vector.new(0,1.1,0))
		end
	end

	for _, player in pairs(core.get_connected_players()) do
		-- Wind acceleration
		local wind = winter.wind(player:get_pos())
		local wind_shelter_ratio = 1 - (wind_shelter_cache[player:get_player_name()] or 0)
		local player_vel_along_wind = (player:get_velocity() / wind:length()):dot(wind:normalize())
		player:add_velocity(wind * wind_shelter_ratio * winter.wind_force * (1 - player_vel_along_wind) * dtime)

	end

	physics_update_timer = physics_update_timer + dtime
	if physics_update_timer > physics_update_interval then
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
	end
end)