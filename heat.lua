


winter.heat_nodes = {
	["fire:permanent_flame"] = 70,
	["fire:basic_flame"] = 70,
	["default:torch"] = 10,
}
local heat_nodenames = {}
for k,_ in pairs(winter.heat_nodes) do heat_nodenames[#heat_nodenames + 1] = k end


local heat_dropoff_curve = function(distance)
	return 4 / (4 + distance + 1)
end

-- Returns the temperature at pos due to fire, body warmth, etc.
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
	return total_node_heat
end