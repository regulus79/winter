

--
-- Debug HUD
--

local player_debug_ids = {}
local player_debug_enabled = {}

local debug_string = function(player)
	local pos = player:get_pos()
	local real_outside_temp = winter.raw_outside_temperature(pos)
	local local_temperature = winter.get_cached(player, "specific_temperature")
	local feels_like_temp = winter.get_cached(player, "feels_like_temp")
	local current_body_temp = player:get_meta():get_float("body_temperature")
	local temp_difference = feels_like_temp - current_body_temp
	local wetness = player:get_meta():get_float("wetness")
	local initial_heat_loss_rate = player:get_meta():get_float("body_heat_loss_rate")
	local heat_loss_rate = winter.heat_loss_rate(player)
	local metabolism = winter.metabolism(player)
	local temp_change = heat_loss_rate * temp_difference + metabolism

	-- Calculate predicted body temp which you will stable out to
	-- Basically when total_heat_loss_rate * temp_difference + metabolism = 0
	-- => total_heat_loss_rate * temp_difference = -metabolism
	-- => (initial_heat_loss_rate + wetness * winter.wetness_heat_loss_rate) * temp_difference = -metabolism
	-- => temp_difference = metabolism / (initial_heat_loss_rate + wetness * winter.wetness_heat_loss_rate)
	-- And add that temp difference to the current temperature
	local predicted_steady_temp_difference = metabolism / (initial_heat_loss_rate + wetness * winter.wetness_heat_loss_rate)
	local predicted_steady_body_temp = feels_like_temp + predicted_steady_temp_difference
	info = {
		"Weather Intensity:\n   " .. tostring(winter.general_weather_intensity(pos)),
		"Wind Speed:\n   " .. tostring(winter.wind(pos):length()),
		"External Temp:\n   " .. tostring(real_outside_temp),
		"Local Temp:\n   " .. tostring(local_temperature),
		"Temp Sheltered:\n   " .. tostring(winter.get_cached(player, "temp_sheltered")),
		"Wind Sheltered:\n   " .. tostring(winter.get_cached(player, "wind_sheltered")),
		"Feels like temp:\n   " .. tostring(feels_like_temp),
		"Body Temp:\n   " .. tostring(current_body_temp),
		"Temp Difference:\n   " .. tostring(temp_difference),
		"Wetness:\n   " .. tostring(wetness),
		"Clothing heat loss:\n   " .. tostring(initial_heat_loss_rate),
		"Clothing+wetness heat loss:\n   " .. tostring(heat_loss_rate),
		"Heat Loss Rate:\n   " .. tostring(heat_loss_rate * temp_difference),
		"Metabolism:\n   " .. tostring(metabolism),
		"Body Temp Change:\n   " .. tostring(temp_change),
		"Predicted Steady Body Temp:\n   " .. tostring(predicted_steady_body_temp),
	}
	return table.concat(info, "\n")
end

core.register_on_joinplayer(function(player)
	player_debug_ids[player:get_player_name()] = player:hud_add({
		type = "text",
		position = {x = 0, y = 0.2},
		offset = {x = 24, y = 0},
		size = {x = 1, y = 0},
		alignment = {x = 1, y = 1},
		number = 0x33AAFF,
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
	func = function(name, param)
		winter.invincible_players[name] = not winter.invincible_players[name]
		if winter.invincible_players[name] then
			core.chat_send_player(name, "You are now invincible to cold!")
		else
			core.chat_send_player(name, "You are now invincible to cold!")
		end
		local player = core.get_player_by_name(name)
		player:get_meta():set_float("body_temperature", winter.target_body_temperature)
		player:get_meta():set_float("wetness", 0)
	end
})
