
local player_statbar_ids = {}
local player_infotext_ids = {}
local player_warning_ids = {}
local player_vingette_ids = {}
local player_vingette_current = {}
local player_vingette_targets = {}

local max_cold = 16

-- This may be redefined in hunger.lua depending on what other statbar mods are enabled
winter.cold_statbar_offset = {x = 24, y = -89}
-- Offset when breath bubbles statbar is showing
winter.cold_statbar_breath_offset = {x = 24, y = -112}

core.register_on_joinplayer(function(player)
	player_statbar_ids[player:get_player_name()] = player:hud_add({
		type = "statbar",
		position = {x = 0.5, y = 1},
		offset = winter.cold_statbar_offset,
		size = {x = 24, y = 24},
		direction = 0,
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
	player_warning_ids[player:get_player_name()] = player:hud_add({
		type = "text",
		position = {x = 0.5, y = 0},
		offset = {x = 0, y = 20},
		size = {x = 3, y = 0},
		alignment = {x = 0, y = 1},
		number = 0xAAAAAA,
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
	local feels_like_temp = winter.get_cached(player, "feels_like_temp")
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


local warning_text = function(player)
	local output = ""
	if winter.is_in_winter_storm(player) then
		output = output .. "WINTER STORM"
	end
	return output
end


local temp_to_stat = function(temp)
	local difference_from_body_temp = winter.target_body_temperature - temp
	return math.round(math.max(0, max_cold * difference_from_body_temp / (winter.target_body_temperature - winter.deadly_body_temperature)))
end



winter.register_timer("temperature_update", 0, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local body_temp_change_rate = winter.change_in_body_temp(player)
		-- TODO move this out of gui.lua
		-- Disable overheating with math.min
		local new_body_temp = math.min(player:get_meta():get_float("body_temperature") + body_temp_change_rate * dtime, winter.target_body_temperature)
		winter.set_body_temp(player, new_body_temp, dtime)
		winter.apply_hunger(player, winter.metabolism(player) * winter.hunger_per_metabolism * dtime)

		-- Update statbar
		local new_cold_stat = temp_to_stat(new_body_temp)
		player:get_meta():set_float("cold_stat", new_cold_stat)
		player:hud_change(player_statbar_ids[player:get_player_name()], "number", new_cold_stat)
		player:hud_change(player_statbar_ids[player:get_player_name()], "offset", (player:get_breath() < player:get_properties().breath_max) and winter.cold_statbar_breath_offset or winter.cold_statbar_offset)

		-- Update vingette targets
		player_vingette_targets[player:get_player_name()] = math.min(0.5, math.max(-0.5, body_temp_change_rate))
	end
end)

-- Update the vignette opacities, kind of interpolating them so that we don't have to do so many calculations
winter.register_timer("vignette_update", 0.1, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local current = player_vingette_current[player:get_player_name()]
		local target = player_vingette_targets[player:get_player_name()]
		local opacity = math.min(255, math.abs(255 * (current) / 0.5))
		if current < 0 then
			player:hud_change(player_vingette_ids[player:get_player_name()], "text", "winter_cold_vignette.png^[opacity:" .. tostring(opacity))
		else
			player:hud_change(player_vingette_ids[player:get_player_name()], "text", "winter_warm_vignette.png^[opacity:" .. tostring(opacity))
		end
		local update_amount = math.sign(target - current) * dtime * 0.25
		if math.abs(update_amount) > math.abs(target - current) then
			player_vingette_current[player:get_player_name()] = target
		else
			player_vingette_current[player:get_player_name()] = current + update_amount
		end
	end
end)

winter.register_timer("other_gui_update", 0.5, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		player:hud_change(player_infotext_ids[player:get_player_name()], "text", infotext_string(player))
		player:hud_change(player_warning_ids[player:get_player_name()], "text", warning_text(player))
	end
end)

