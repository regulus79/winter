
if core.get_modpath("default") then
	minetest.register_on_mods_loaded(function()
		old_biomes = {}
		for i,v in pairs(core.registered_biomes) do
			old_biomes[i] = v
		end
		core.clear_registered_biomes()
		for _, biome in pairs(old_biomes) do
			if string.find(biome.name, "snow") or string.find(biome.name, "ice") then
				core.register_biome(biome)
			end
		end
	end)
end
