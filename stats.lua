
local player_statbar_ids = {}

local initial_cold = 0
local max_cold = 16

core.register_on_newplayer(function(player)
	player:get_meta():set_float("cold_stat", initial_cold)
	player:get_meta():set_float("body_temperature", winter.target_body_temperature)
	player:get_meta():set_float("body_heat_loss_rate", winter.default_body_heat_loss_rate)
	player:get_meta():set_float("metabolism_rate", winter.default_metabolism_rate)
end)

core.register_on_joinplayer(function(player)
	player_statbar_ids[player:get_player_name()] = player:hud_add({
		type = "statbar",
		position = {x = 0.5, y = 1},
		offset = {x = -265 + 265 + 24, y = -89},
		size = {x = 24, y = 24},
		text = "winter_stat_snowflake.png",
		text2 = "winter_stat_warm.png",
		number = player:get_meta():get_float("cold_stat"),
		item = 16,
	})
end)


winter.cold_hp_loss_rate = 0.1
winter.set_body_temp = function(player, temp, deltatime)
	player:get_meta():set_float("body_temperature", temp)
	if temp < winter.deadly_body_temperature then
		local hp_loss = winter.cold_hp_loss_rate * deltatime
		if hp_loss < 1 then
			hp_loss = (math.random() < hp_loss and 1 or 0)
		end
		player:set_hp(player:get_hp() - hp_loss * deltatime)
	end
end



local temp_to_stat = function(temp)
	local difference_from_body_temp = winter.target_body_temperature - temp
	return math.round(math.max(0, max_cold * difference_from_body_temp / (winter.target_body_temperature - winter.deadly_body_temperature)))
end


local temperature_update_timer = 0
local temperature_update_interval = 4
core.register_globalstep(function(dtime)
	temperature_update_timer = temperature_update_timer + dtime
	if temperature_update_timer > temperature_update_interval then
		temperature_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			local body_temp_change = winter.change_in_body_temp(player) * temperature_update_interval
			-- Disable overheating with math.min
			local new_body_temp = math.min(player:get_meta():get_float("body_temperature") + body_temp_change, winter.target_body_temperature)
			winter.set_body_temp(player, new_body_temp, temperature_update_interval)

			local new_cold_stat = temp_to_stat(new_body_temp)
			player:get_meta():set_float("cold_stat", new_cold_stat)
			player:hud_change(player_statbar_ids[player:get_player_name()], "number", new_cold_stat)

			minetest.debug("New body temp:", new_body_temp, "Delta:", body_temp_change, "New Stat:",new_cold_stat)
		end
	end
end)