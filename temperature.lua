

--
-- Body Temperature
--

winter.target_body_temperature = 37
winter.decent_body_temperature = 30
winter.chilly_body_temperature = 20
winter.deadly_body_temperature = 10
-- TODO: change to function to allow different clothing to affect cold tolerance
winter.default_body_heat_loss_rate = 0.005
winter.default_metabolism_rate = 0.1

winter.cold_hp_loss_rate_per_degree = 0.1

winter.wetness_heat_loss_rate = 0.1



winter.metabolism = function(player)
	local metabolism_rate = player:get_meta():get_float("metabolism_rate")
	local body_temp = player:get_meta():get_float("body_temperature")
	local temp_difference = winter.target_body_temperature - body_temp
	-- Using min/max clamp to ramp down metabolism as you approach normal temp, otherwise the predicted body temp goes crazy.
	-- But then again the user doesn't see that so maybe it's fine idk
	return math.max(-metabolism_rate, math.min(metabolism_rate, temp_difference * metabolism_rate))
end

winter.heat_loss_rate = function(player)
	local heat_loss_rate = player:get_meta():get_float("body_heat_loss_rate")
	local wetness = player:get_meta():get_float("wetness")
	return heat_loss_rate + wetness * winter.wetness_heat_loss_rate
end

-- Returns the rate of change in body temp
-- Heat loss rate depends on the clothing being worn
winter.change_in_body_temp = function(player)
	local external_temp = winter.get_cached(player, "feels_like_temp")
	local current_body_temp = player:get_meta():get_float("body_temperature")
	local heat_loss_rate = winter.heat_loss_rate(player)
	local metabolism = winter.metabolism(player)
	local temp_difference = external_temp - current_body_temp
	local temp_change = heat_loss_rate * temp_difference + metabolism
	return temp_change
end


winter.set_body_temp = function(player, temp, deltatime)
	player:get_meta():set_float("body_temperature", temp)
	if temp < winter.deadly_body_temperature then
		local hp_loss = winter.cold_hp_loss_rate_per_degree * (winter.deadly_body_temperature - temp) * deltatime
		if hp_loss < 1 then
			hp_loss = (math.random() < hp_loss) and 1 or 0
		end
		player:set_hp(player:get_hp() - hp_loss)
	end
end

--
-- Shelter
--

local ray_length = 8
local ray_directions = {
	vector.new(0,1,0):normalize(),
	vector.new(0,-1,0):normalize(),
}

for i = 1,16 do
	table.insert(ray_directions, vector.new(math.cos(2 * math.pi * i / 16), 0.3, math.sin(2 * math.pi * i / 16)):normalize())
	table.insert(ray_directions, vector.new(math.cos(2 * math.pi * i / 16), -0.3, math.sin(2 * math.pi * i / 16)):normalize())
end
for i = 1,8 do
	table.insert(ray_directions, vector.new(math.cos(2 * math.pi * i / 8), 2, math.sin(2 * math.pi * i / 8)):normalize())
	table.insert(ray_directions, vector.new(math.cos(2 * math.pi * i / 8), -2, math.sin(2 * math.pi * i / 8)):normalize())
end

local ray_pointabilities = {
	nodes = {
		["group:leaves"] = false,
		["default:snow"] = false,
	}
}

-- Returns two numbers from 0 to 1 indicating how sheltered the position is from the outside and the wind
-- 0 means completely unsheltered, 1 is perfectly sheltered
winter.sheltered = function(pos)
	local current_wind_dir = winter.wind(pos):normalize()
	local temp_sheltered_score = 0
	local wind_sheltered_score = 0
	for _, dir in pairs(ray_directions) do
		local hit = core.raycast(pos, pos + dir * ray_length, false, false, ray_pointabilities):next()
		if hit then
			-- Count number of wall hits to esitmate surroundings
			temp_sheltered_score = temp_sheltered_score + 1
			-- Use dot product to find similarity to wind vector
			-- If wall direction is opposite wind direction, then it's sheltered well
			-- Adding 1 to make it positive
			wind_sheltered_score = wind_sheltered_score + (1 - current_wind_dir:dot(dir))
		end
	end
	return (temp_sheltered_score / #ray_directions), (wind_sheltered_score / #ray_directions)
end


--
-- "Feels Like" Temperature
--

local wind_chill_weight = 1
local shelter_weight = 1

-- Combine the total temperature (weather + heat sources) with the wind chill and shelter ratio
winter.feels_like_temp = function(player)
	local pos = player:get_pos()
	local temp_shelter = winter.get_cached(player, "temp_sheltered")
	local wind_shelter = winter.get_cached(player, "wind_sheltered")
	-- Total heat, from weather and nodes/players
	local base_temp_outdoors = winter.raw_outside_temperature(pos)
	-- Get heat given off by players, fire, torches, etc, assuming there is/isn't shelter
	-- Without shelter, heat spread off and is swept away quickly, whereas inside a room, heat stays confined
	local heat_source_temp = winter.get_cached(player, "heat_source_temp")

	local outside_chill = base_temp_outdoors * (1 - temp_shelter) + heat_source_temp
	-- And add some wind chill
	local wind_chill = -(1 - wind_shelter) * winter.wind(player:get_pos()):length() * wind_chill_weight
	return outside_chill + wind_chill
end
