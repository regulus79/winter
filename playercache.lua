


winter.cache = {}

-- Cache things like shelter ratio and temperature once every interval, so that we don't have to recalculate them everywhere else
winter.register_timer("cache", 1, function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local playername = player:get_player_name()
		local pos = player:get_pos() + vector.new(0, 1.1, 0)
		if not winter.cache[playername] then winter.cache[playername] = {} end

		winter.cache[playername].temp_sheltered, winter.cache[playername].wind_sheltered = winter.sheltered(pos)
		winter.cache[playername].heat_source_temp = winter.heat_source_temp(pos, winter.cache[playername].temp_sheltered)
		winter.cache[playername].feels_like_temp = winter.feels_like_temp(player)
	end
end)


winter.get_cached = function(player, attribute)
	local playername = player:get_player_name()
	if not winter.cache[playername] then return 0 end
	if not winter.cache[playername][attribute] then return 0 end
	return winter.cache[playername][attribute]
end

