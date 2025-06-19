

--
-- Body Temperature
--

winter.target_body_temperature = 37
winter.decent_body_temperature = 30
winter.chilly_body_temperature = 20
winter.deadly_body_temperature = 10
-- TODO: change to function to allow different clothing to affect cold tolerance
winter.default_body_heat_loss_rate = 0.01
winter.default_metabolism_rate = 0.1

winter.cold_hp_loss_rate = 0.1

winter.wetness_heat_loss_rate = 0.1



winter.metabolism = function(player)
	local food_supply = 1 -- TODO add hunger
	if food_supply <= 0 then
		return 0
	end
	local metabolism_rate = player:get_meta():get_float("metabolism_rate")
	local body_temp = player:get_meta():get_float("body_temperature")
	--minetest.debug("Metabolism: temp difference: ", winter.target_body_temperature - body_temp)
	return math.sign(winter.target_body_temperature - body_temp) * metabolism_rate
end

winter.heat_loss_rate = function(player)
	local heat_loss_rate = player:get_meta():get_float("body_heat_loss_rate")
	local wetness = player:get_meta():get_float("wetness")
	return heat_loss_rate + wetness * winter.wetness_heat_loss_rate
end

-- Returns the rate of change in body temp
-- Heat loss rate depends on the clothing being worn
winter.change_in_body_temp = function(player)
	local external_temp = winter.feels_like_temp(player:get_pos() + vector.new(0,1,0))
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
		local hp_loss = winter.cold_hp_loss_rate * deltatime
		if hp_loss < 1 then
			hp_loss = (math.random() < hp_loss and 1 or 0)
		end
		player:set_hp(player:get_hp() - hp_loss * deltatime)
	end
end

--
-- Shelter
--

local ray_length = 3
local ray_directions = {
	vector.new(1,0,0):normalize(),
	vector.new(1,0,1):normalize(),
	vector.new(0,0,1):normalize(),
	vector.new(-1,0,1):normalize(),
	vector.new(-1,0,0):normalize(),
	vector.new(-1,0,-1):normalize(),
	vector.new(0,0,-1):normalize(),
	vector.new(1,0,-1):normalize(),

	vector.new(1,1,0):normalize(),
	vector.new(-1,1,0):normalize(),
	vector.new(0,1,1):normalize(),
	vector.new(0,1,-1):normalize(),

	vector.new(0,1,0):normalize(),
}
local ray_pointabilities = {
	nodes = {
		["group:leaves"] = false,
		["default:snow"] = false,
	}
}

-- Returns two numbers from 0 to 1 indicating how sheltered the position is from the outside and the wind
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

-- Returns the current temperature due to weather variations at pos
-- Does not take into account the terrain, wind, or fire
-- TODO move to weather.lua
winter.raw_outside_temperature = function(pos)
	return -20
end

winter.total_temperature = function(pos)
	local raw_outside_temp = winter.raw_outside_temperature(pos)
	local local_temperature = winter.specific_temperature(pos)
	return raw_outside_temp + local_temperature
end


local wind_chill_weight = 1
local shelter_weight = 1

winter.feels_like_temp = function(pos)
	local shelter, wind_shelter = winter.sheltered(pos)
	local actual_temp = winter.total_temperature(pos)
	-- Local heat given off by players, fire, torches, etc
	local local_temperature = winter.specific_temperature(pos)
	-- Lerp between actual temp and inside temp based on shelter ratio
	local outside_chill = actual_temp + shelter * (local_temperature - actual_temp) * shelter_weight
	local wind_chill = -(1 - wind_shelter) * winter.wind(pos):length() * wind_chill_weight
	return outside_chill + wind_chill
end
