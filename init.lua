

winter = {}



dofile(core.get_modpath("winter") .. "/mapgens.lua")
dofile(core.get_modpath("winter") .. "/weather.lua")
dofile(core.get_modpath("winter") .. "/heat.lua")
dofile(core.get_modpath("winter") .. "/wetness.lua")
dofile(core.get_modpath("winter") .. "/temperature.lua")
dofile(core.get_modpath("winter") .. "/hud.lua")
dofile(core.get_modpath("winter") .. "/debug.lua")


core.register_on_newplayer(function(player)
	player:get_meta():set_float("cold_stat", 0)
	player:get_meta():set_float("body_temperature", winter.target_body_temperature)
	player:get_meta():set_float("body_heat_loss_rate", winter.default_body_heat_loss_rate)
	player:get_meta():set_float("wetness", 0)
	player:get_meta():set_float("metabolism_rate", winter.default_metabolism_rate)
end)

core.register_on_dieplayer(function(player)
	player:get_meta():set_float("cold_stat", 0)
	player:get_meta():set_float("body_temperature", winter.target_body_temperature)
	player:get_meta():set_float("body_heat_loss_rate", winter.default_body_heat_loss_rate)
	player:get_meta():set_float("wetness", 0)
	player:get_meta():set_float("metabolism_rate", winter.default_metabolism_rate)
end)

