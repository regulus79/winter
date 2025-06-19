
local player_statbar_ids = {}

local initial_cold = 0
local max_cold = 16

core.register_on_newplayer(function(player)
	player:get_meta():set_int("cold", initial_cold)
end)

core.register_on_joinplayer(function(player)
	player_statbar_ids[player:get_player_name()] = player:hud_add({
		type = "statbar",
		position = {x = 0.5, y = 0.5},
		text = "default_snow.png",
		text2 = "default_dirt.png",
		number = player:get_meta():get_float("cold"),
		item = 16,
	})
end)

local temperature_update_timer = 0
local temperature_update_interval = 5
local temperature_update_lerp = 1 - math.pow((1 - 0.5), 1 / temperature_update_interval)
core.register_globalstep(function(dtime)
	temperature_update_timer = temperature_update_timer + dtime
	if temperature_update_timer > temperature_update_interval then
		temperature_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			local temp = winter.feels_like_temp(player:get_pos() + vector.new(0,1,0))
			local difference = temp - winter.body_tolerable_temp
			local as_score = math.max(0, -difference)

			local current_cold = player:get_meta():get_float("cold", 0)
			local cold_change = (as_score - current_cold) * temperature_update_lerp
			minetest.debug(temp, difference, as_score, current_cold, cold_change)

			local new_cold = math.max(0, math.min(current_cold + cold_change, max_cold))
			player:get_meta():set_float("cold", new_cold)
			player:hud_change(player_statbar_ids[player:get_player_name()], "number", math.round(new_cold))
		end
	end
end)