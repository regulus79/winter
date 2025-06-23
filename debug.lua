

--
-- Debug HUD
--

local player_debug_ids = {}
local player_debug_enabled = {}

local debug_string = function(player)
	local pos = player:get_pos()
	local real_outside_temp = winter.raw_outside_temperature(pos)
	local heat_source_temp = winter.get_cached(player, "heat_source_temp")
	local feels_like_temp = winter.get_cached(player, "feels_like_temp")
	local current_body_temp = player:get_meta():get_float("body_temperature")
	local temp_difference = feels_like_temp - current_body_temp
	local wetness = player:get_meta():get_float("wetness")
	local body_thermal_conductivity = winter.default_body_thermal_conductivity
	local thermal_conductivity = winter.thermal_conductivity(player)
	local metabolism = winter.metabolism(player)
	local temp_change = winter.body_temp_change_rate(player)
	local surface_area = winter.body_surface_area

	local clothing = winter.get_clothing(player)

	-- Calculate predicted body temp which you will stable out to
	-- Basically when thermal_conductivity * temp_diff_body_outside * surface_area + metabolism_rate = 0
	-- => thermal_conductivity * temp_diff_body_outside * surface_area + metabolism_rate = 0
	-- => temp_diff_body_outside = -metabolism_rate / (thermal_conductivity * surface_area)

	-- Also for note, we want that to equal 0 when temp_diff = room_temp - body_temp for realism
	-- So (room_temp - body_temp) = -metabolism_rate / (thermal_conductivity * surface_area)
	-- (22 - 37) = -metabolism_rate / (thermal_conductivity * surface_area)
	-- -15 = -metabolism_rate / (thermal_conductivity * surface_area)
	-- 15 = metabolism_rate / (thermal_conductivity * surface_area)
	-- 15 * (thermal_conductivity * surface_area) = metabolism_rate
	-- Plug some numbers in
	-- 15 * (2.4 * 1,7) = metabolism_rate
	-- 61.2 = metabolism_rate

	--local predicted_steady_body_temp = (thermal_conductivity * real_outside_temp * surface_area + winter.default_metabolism_rate * winter.target_body_temperature / 10) / (thermal_conductivity * surface_area + winter.default_metabolism_rate / 10)
	local predicted_steady_temp_difference = -metabolism / (thermal_conductivity * surface_area)
	local predicted_steady_body_temp = feels_like_temp - predicted_steady_temp_difference
	info = {
		"Weather Intensity:\n   " .. tostring(winter.general_weather_intensity(pos)),
		"Wind Speed:\n   " .. tostring(winter.wind(pos):length()),
		"External Temp:\n   " .. tostring(real_outside_temp),
		"Heat Source Temp:\n   " .. tostring(heat_source_temp),
		"Temp Sheltered:\n   " .. tostring(winter.get_cached(player, "temp_sheltered")),
		"Wind Sheltered:\n   " .. tostring(winter.get_cached(player, "wind_sheltered")),
		"Feels like temp:\n   " .. tostring(feels_like_temp),
		"Body Temp:\n   " .. tostring(current_body_temp),
		"Temp Difference:\n   " .. tostring(temp_difference),
		"Wetness:\n   " .. tostring(wetness),
		"Body Thermal Conductivity:\n   " .. tostring(body_thermal_conductivity),
		"Head Conductivity:\n   " .. tostring(winter.get_clothing_group_conductivity(clothing, "armor_head")),
		"Torso Conductivity:\n   " .. tostring(winter.get_clothing_group_conductivity(clothing, "armor_torso")),
		"Legs Conductivity:\n   " .. tostring(winter.get_clothing_group_conductivity(clothing, "armor_legs")),
		"Feet Conductivity:\n   " .. tostring(winter.get_clothing_group_conductivity(clothing, "armor_feet")),
		"Total Thermal Conductivity:\n   " .. tostring(thermal_conductivity),
		"Heat Transfer Rate:\n   " .. tostring(thermal_conductivity * temp_difference),
		"Metabolism:\n   " .. tostring(metabolism),
		"Body Temp Change:\n   " .. tostring(temp_change),
		"Predicted Steady Body Temp:\n   " .. tostring(predicted_steady_body_temp),
	}
	return table.concat(info, "\n")
end

core.register_on_joinplayer(function(player)
	player_debug_ids[player:get_player_name()] = player:hud_add({
		type = "text",
		position = {x = 0, y = 0.1},
		offset = {x = 24, y = 0},
		size = {x = 1, y = 0},
		alignment = {x = 1, y = 1},
		number = 0x000000,
		text = ""
	})
end)


winter.register_timer("debug_info", 0.25, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		if player_debug_enabled[player:get_player_name()] then
			player:hud_change(player_debug_ids[player:get_player_name()], "text", debug_string(player))
		else
			player:hud_change(player_debug_ids[player:get_player_name()], "text", "")
		end
	end
end)


--
-- Debug commands
--

core.register_chatcommand("debuginfo", {
	description = "Toggle the winter debug display (temperature, wetness, heat loss, metabolism, etc) for your player",
	privs = {server = 1},
	func = function(name, param)
		player_debug_enabled[name] = not player_debug_enabled[name]
	end
})


--
-- Admin commands
--

winter.invincible_players = {}

core.register_chatcommand("alwayswarm", {
	description = "Make player invincible to cold",
	privs = {server = 1},
	func = function(name, param)
		winter.invincible_players[name] = not winter.invincible_players[name]
		if winter.invincible_players[name] then
			core.chat_send_player(name, "You are now invincible to cold!")
		else
			core.chat_send_player(name, "You are no longer invincible to cold!")
		end
		local player = core.get_player_by_name(name)
		player:get_meta():set_float("body_temperature", winter.target_body_temperature)
		player:get_meta():set_float("wetness", 0)
	end
})

core.register_chatcommand("resetheat", {
	description = "Reset player body temp and wetness",
	privs = {server = 1},
	func = function(name, param)
		local player = core.get_player_by_name(name)
		player:get_meta():set_float("body_temperature", winter.target_body_temperature)
		player:get_meta():set_float("wetness", 0)
	end
})

core.register_chatcommand("settemp", {
	description = "Set your current body temperature",
	privs = {server = 1},
	func = function(name, param)
		if not tonumber(param) then return end
		local player = core.get_player_by_name(name)
		player:get_meta():set_float("body_temperature", tonumber(param))
	end
})