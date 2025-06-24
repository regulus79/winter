


--
-- This doesn't sound as good as I wanted lol
-- The white noise-based wind sounds sickening at times
--

local wind_sound_handles = {}
local wind_lowpassed_sound_handles = {}
local wind_very_lowpassed_sound_handles = {}

local wind_volume = 0.1

core.register_on_joinplayer(function(player)
	wind_sound_handles[player:get_player_name()] = core.sound_play({name = "wind2", gain = 0.1, fade = 1.0}, {to_player = player:get_player_name(), loop = true})
	wind_lowpassed_sound_handles[player:get_player_name()] = core.sound_play({name = "wind2_lowpass1", gain = 0.1, fade = 1.0}, {to_player = player:get_player_name(), loop = true})
	wind_very_lowpassed_sound_handles[player:get_player_name()] = core.sound_play({name = "wind2_lowpass2", gain = 0.1, fade = 1.0}, {to_player = player:get_player_name(), loop = true})
end)


winter.register_timer("update_wind_volume", 0.25, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local wind_speed = winter.wind(player:get_pos()):length() / 20
		local wind_sheltered = winter.get_cached(player, "wind_sheltered")
		local t = wind_speed * (1 - wind_sheltered)
		local weight1 = (t - 1)^2
		local weight2 = -2*t^2 + 2*t
		local weight3 = t^2
		-- adding 0.001 to make sure it doesn't delete itself
		core.sound_fade(wind_lowpassed_sound_handles[player:get_player_name()], 0.1, wind_volume * weight1 + 0.001)
		core.sound_fade(wind_lowpassed_sound_handles[player:get_player_name()], 0.1, wind_volume * weight2 + 0.001)
		core.sound_fade(wind_sound_handles[player:get_player_name()], 0.1, wind_volume * weight3 + 0.001)
	end
end)