


winter.heat_nodes = {
	["fire:permanent_flame"] = 70,
	["fire:basic_flame"] = 70,
	["default:torch_wall"] = 3,
	["default:torch"] = 3,
	["default:furnace_active"] = 50,
}
local heat_nodenames = {}
for k,_ in pairs(winter.heat_nodes) do heat_nodenames[#heat_nodenames + 1] = k end


local heat_dropoff_curve = function(distance)
	-- Not doing a real 1/x^2 curve since that isn't nice around the origin. This way you don't get infinite heat when you go up close to it
	return 1 / (1 + distance^2)
end

-- Returns the temperature at pos due to fire, body warmth, etc.
-- Also geothermal heat, I just realized
-- Unlike winter.raw_outside_temperature, which handles the weather
local heat_search_size = 5
winter.specific_temperature = function(pos)
	local total_node_heat = 0
	local nearby_heat_sources = core.find_nodes_in_area(
		pos - vector.new(-heat_search_size, -heat_search_size, -heat_search_size),
		pos - vector.new(heat_search_size, heat_search_size, heat_search_size),
		heat_nodenames,
		true
	)
	for nodename, poslist in pairs(nearby_heat_sources) do
		local nodeheat = winter.heat_nodes[nodename]
		for _, nodepos in pairs(poslist) do
			total_node_heat = total_node_heat + heat_dropoff_curve(nodepos:distance(pos)) * nodeheat
		end
	end
	-- yes technically we already accounted for the altitude in the general weather intensity but..... idk
	local geothermal_heat = -pos.y / 10
	return total_node_heat + geothermal_heat
end
