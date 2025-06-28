
-- If you are in shelter, make the heat spread out more
winter.indoor_heat_source_dropoff = 30
-- If you can't directly see the heat source, decrease it's range
winter.indirect_heat_source_dropoff_multiplier = 0.3
-- Geothermal heat degrees per meter. The deeper you go, the warmer it gets.
winter.geothermal_constant = 0.05

winter.heat_nodes = {
	["fire:permanent_flame"] = 70,
	["fire:basic_flame"] = 70,
	["default:torch_wall"] = 3,
	["default:torch"] = 3,
	["default:furnace_active"] = 50,
	["tcj_fire:stick_bundle_burning1"] = 10,
	["tcj_fire:stick_bundle_burning2"] = 20,
	["tcj_fire:stick_bundle_burning3"] = 30,
	["tcj_fire:stick_bundle_burning4"] = 40,
	["tcj_fire:stick_bundle_burning5"] = 50,
	["tcj_fire:stick_bundle_burning6"] = 60,
}
local heat_nodenames = {}
for k,_ in pairs(winter.heat_nodes) do heat_nodenames[#heat_nodenames + 1] = k end


local heat_dropoff_curve = function(distance, dropoff)
	-- Not doing a real 1/x^2 curve since that isn't nice around the origin. This way you don't get infinite heat when you go up close to it
	return dropoff / (dropoff + distance^2)
end

-- Returns the temperature at pos due to fire, body warmth, etc.
-- Also geothermal heat
-- Unlike winter.raw_outside_temperature, which handles the weather
-- The dropoff aprameter controls the steepness of the heat dropoff curve. Indoors, heat tends to accumulate and spread out, whereas outdoors it is easily swept away unless you are close to the source.
local heat_search_size = 10
winter.heat_source_temp = function(pos, shelter)
	local dropoff = 1 + shelter * winter.indoor_heat_source_dropoff
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
			local hit = core.raycast(pos, nodepos, false, false):next()
			-- If you can't see the node, make the dropoff steeper
			if not hit or hit.under == nodepos then
				total_node_heat = total_node_heat + heat_dropoff_curve(nodepos:distance(pos), dropoff) * nodeheat
			else
				total_node_heat = total_node_heat + heat_dropoff_curve(nodepos:distance(pos), dropoff * winter.indirect_heat_source_dropoff_multiplier) * nodeheat
			end
		end
	end
	-- yes technically we already accounted for the altitude in the general weather intensity but..... idk
	local geothermal_heat = -pos.y * winter.geothermal_constant
	return total_node_heat + geothermal_heat
end
