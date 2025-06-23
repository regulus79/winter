

winter = {}



dofile(core.get_modpath("winter") .. "/helperfunctions.lua")
dofile(core.get_modpath("winter") .. "/mapgens.lua")
dofile(core.get_modpath("winter") .. "/weather.lua")
dofile(core.get_modpath("winter") .. "/heatsources.lua")
dofile(core.get_modpath("winter") .. "/wetness.lua")
dofile(core.get_modpath("winter") .. "/temperature.lua")
dofile(core.get_modpath("winter") .. "/playercache.lua")
dofile(core.get_modpath("winter") .. "/hud.lua")
dofile(core.get_modpath("winter") .. "/movement.lua")
dofile(core.get_modpath("winter") .. "/debug.lua")
dofile(core.get_modpath("winter") .. "/hunger.lua")
dofile(core.get_modpath("winter") .. "/clothing.lua")
dofile(core.get_modpath("winter") .. "/snowblocks.lua")


core.register_on_newplayer(function(player)
	player:get_meta():set_float("cold_stat", 0)
	player:get_meta():set_float("body_temperature", winter.target_body_temperature)
	player:get_meta():set_float("wetness", 0)
end)

core.register_on_respawnplayer(function(player)
	player:get_meta():set_float("cold_stat", 0)
	player:get_meta():set_float("body_temperature", winter.target_body_temperature)
	player:get_meta():set_float("wetness", 0)
end)

