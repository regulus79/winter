

--
-- Debug HUD
--

local player_debug_ids = {}
local player_debug_enabled = {}

local debug_string = function(player)
	local pos = player:get_pos()
	local real_outside_temp = winter.raw_outside_temperature(pos)
	local local_temperature = winter.specific_temperature(pos)
	local feels_like_temp = winter.feels_like_temp(pos + vector.new(0,1,0))
	local current_body_temp = player:get_meta():get_float("body_temperature")
	local temp_difference = feels_like_temp - current_body_temp
	local wetness = player:get_meta():get_float("wetness")
	local heat_loss_rate = winter.heat_loss_rate(player)
	local metabolism = winter.metabolism(player)
	local temp_change = heat_loss_rate * temp_difference + metabolism
	info = {
		"Weather Intensity:\n   " .. tostring(winter.general_weather_intensity(pos)),
		"External Temp:\n   " .. tostring(real_outside_temp),
		"Local Temp:\n   " .. tostring(local_temperature),
		"Feels like temp:\n   " .. tostring(feels_like_temp),
		"Body Temp:\n   " .. tostring(current_body_temp),
		"Temp Difference:\n   " .. tostring(temp_difference),
		"Wetness:\n   " .. tostring(wetness),
		"Heat Loss:\n   " .. tostring(heat_loss_rate * temp_difference),
		"Metabolism:\n   " .. tostring(metabolism),
		"Body Temp Change:\n   " .. tostring(temp_change),
	}
	return table.concat(info, "\n")
end

core.register_on_joinplayer(function(player)
	player_debug_ids[player:get_player_name()] = player:hud_add({
		type = "text",
		position = {x = 0, y = 0.3},
		offset = {x = 24, y = 0},
		size = {x = 1, y = 0},
		alignment = {x = 1, y = 0},
		number = 0x33AAFF,
		text = ""
	})
end)

local debug_update_timer = 0
local debug_update_interval = 0.25
core.register_globalstep(function(dtime)
	debug_update_timer = debug_update_timer + dtime
	if debug_update_timer > debug_update_interval then
		debug_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			if player_debug_enabled[player:get_player_name()] then
				player:hud_change(player_debug_ids[player:get_player_name()], "text", debug_string(player))
			else
				player:hud_change(player_debug_ids[player:get_player_name()], "text", "")
			end
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