

winter.body_temp = 37
-- TODO: change to function to allow different clothing to affect cold tolerance
winter.body_tolerable_temp = 10


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

winter.outside_temperature = function(pos)
	return -20
end

local wind_chill_weight = 1
local shelter_weight = 0.5

winter.feels_like_temp = function(pos)
	local shelter, wind_shelter = winter.sheltered(pos)
	local real_outside_temp = winter.outside_temperature(pos)
	local outside_chill = real_outside_temp + shelter * (winter.body_temp - real_outside_temp) * shelter_weight
	local wind_chill = -(1 - wind_shelter) * winter.wind(pos):length() * wind_chill_weight
	return outside_chill + wind_chill
end
