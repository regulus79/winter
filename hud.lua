
local player_statbar_ids = {}
local player_infotext_ids = {}
local player_vingette_ids = {}
local player_vingette_current = {}
local player_vingette_targets = {}

local max_cold = 16

core.register_on_joinplayer(function(player)
	player_statbar_ids[player:get_player_name()] = player:hud_add({
		type = "statbar",
		position = {x = 0.5, y = 1},
		offset = {x = -265 + 265 + 24, y = -89},
		size = {x = 24, y = 24},
		text = "winter_stat_snowflake.png",
		number = player:get_meta():get_float("cold_stat"),
	})
	player_infotext_ids[player:get_player_name()] = player:hud_add({
		type = "text",
		position = {x = 0.5, y = 1},
		offset = {x = 0, y = -120},
		size = {x = 1, y = 0},
		alignment = {x = 0, y = -1},
		text = "",
		z_index = 100,
	})
	player_vingette_targets[player:get_player_name()] = 0
	player_vingette_current[player:get_player_name()] = 0
	player_vingette_ids[player:get_player_name()] = player:hud_add({
		type = "image",
		position = {x = 0, y = 0},
		scale = {x = -100, y = -100},
		alignment = {x = 1, y = 1},
		text = "",
	})
end)



local infotext_string = function(player)
	local current_body_temp = player:get_meta():get_float("body_temperature")
	local feels_like_temp = winter.feels_like_temp(player:get_pos() + vector.new(0,1,0))
	local wetness = player:get_meta():get_float("wetness")
	local output = ""
	if current_body_temp < winter.deadly_body_temperature then
		output = output .. minetest.colorize("#7777cc", string.format("Body Temp: %.1f (!!!)", current_body_temp))
	elseif current_body_temp < winter.chilly_body_temperature then
		output = output .. minetest.colorize("#aaaacc", string.format("Body Temp: %.1f (!!)", current_body_temp))
	elseif current_body_temp < winter.decent_body_temperature then
		output = output .. minetest.colorize("#ccaaaa", string.format("Body Temp: %.1f (!)", current_body_temp))
	else
		output = output .. minetest.colorize("#ffaaaa", string.format("Body Temp: %.1f", current_body_temp))
	end
	output = output .. string.format("\nFeels like: %.1f", feels_like_temp)
	if wetness > 0.7 then
		output = output .. minetest.colorize("#5555ff", "\nSopping wet (!!!)")
	elseif wetness > 0.5 then
		output = output .. minetest.colorize("#7777ee", "\nVery wet (!!)")
	elseif wetness > 0.2 then
		output = output .. minetest.colorize("#9999dd", "\nWet (!)")
	elseif wetness > 0 then
		output = output .. minetest.colorize("#aaaacc", "\nDamp")
	end
	return output
end


local temp_to_stat = function(temp)
	local difference_from_body_temp = winter.target_body_temperature - temp
	return math.round(math.max(0, max_cold * difference_from_body_temp / (winter.target_body_temperature - winter.deadly_body_temperature)))
end


local temperature_update_timer = 0
local temperature_update_interval = 1
local vignette_update_timer = 0
local vignette_update_interval = 0.1
local infotext_update_timer = 0
local infotext_update_interval = 0.5
core.register_globalstep(function(dtime)
	temperature_update_timer = temperature_update_timer + dtime
	if temperature_update_timer > temperature_update_interval then
		temperature_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			local body_temp_change_rate = winter.change_in_body_temp(player)
			-- Disable overheating with math.min
			local new_body_temp = math.min(player:get_meta():get_float("body_temperature") + body_temp_change_rate * temperature_update_interval, winter.target_body_temperature)
			winter.set_body_temp(player, new_body_temp, temperature_update_interval)

			-- Update statbar
			local new_cold_stat = temp_to_stat(new_body_temp)
			player:get_meta():set_float("cold_stat", new_cold_stat)
			player:hud_change(player_statbar_ids[player:get_player_name()], "number", new_cold_stat)

			-- Update vingette targets
			player_vingette_targets[player:get_player_name()] = body_temp_change_rate
		end
	end
	-- Update the vignette opacities, kind of interpolating them so that we don't have to do so many calculations
	vignette_update_timer = vignette_update_timer + dtime
	if vignette_update_timer > vignette_update_interval then
		vignette_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			local current = player_vingette_current[player:get_player_name()]
			local target = player_vingette_targets[player:get_player_name()]
			local opacity = math.min(255, math.abs(255 * (current) / 0.5))
			if current < 0 then
				player:hud_change(player_vingette_ids[player:get_player_name()], "text", "winter_cold_vignette.png^[opacity:" .. tostring(opacity))
			else
				player:hud_change(player_vingette_ids[player:get_player_name()], "text", "winter_warm_vignette.png^[opacity:" .. tostring(opacity))
			end
			local update_amount = math.sign(target - current) * vignette_update_interval * 0.25
			if math.abs(update_amount) > math.abs(target - current) then
				player_vingette_current[player:get_player_name()] = target
			else
				player_vingette_current[player:get_player_name()] = current + update_amount
			end
		end
	end
	-- Update info text above hotbar
	infotext_update_timer = infotext_update_timer + dtime
	if infotext_update_timer > infotext_update_interval then
		infotext_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			player:hud_change(player_infotext_ids[player:get_player_name()], "text", infotext_string(player))
		end
	end
end)






--
-- Debug info
--

local player_debug_ids = {}

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
		text = debug_string(player)
	})
end)

local debug_update_timer = 0
local debug_update_interval = 0.25
core.register_globalstep(function(dtime)
	debug_update_timer = debug_update_timer + dtime
	if debug_update_timer > debug_update_interval then
		debug_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			player:hud_change(player_debug_ids[player:get_player_name()], "text", debug_string(player))
		end
	end
end)