

--
-- Body Temperature
--

winter.target_body_temperature = 37
winter.decent_body_temperature = 35
winter.chilly_body_temperature = 33
winter.deadly_body_temperature = 30

winter.cold_hp_loss_rate_per_degree = 0.1

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
-- Heat Transfer
--

-- I basically copied the specific heat of water, since people are like water, right?
-- Dividing for testing to make the process faster
winter.body_specific_heat = 4184 / 1000
-- Just a guess-- it should be round water maybe, which is 0.6
-- Actually affter testing it seems it needs to be way higher
winter.default_body_thermal_conductivity = 2.5
-- TODO make this customizable. Or not? idk
winter.default_body_mass = 60
-- Random number I found online
winter.body_surface_area = 1.7

-- TODO make this meaningful, like in terms of calories or idk
-- If a normal human uses 2000 kCals per day = 8368000 J per 86400 seconds = 96.9 J/s
-- That's probably too high though, since not all the energy becomes heat (right?)
winter.default_metabolism_rate = 96.9

-- This is wrong, the reason water cools you is due to evaporation, not only conduction.
-- However, it's probably fine to model it as an extreme increase in conductivity
winter.wetness_thermal_conductivity = 10


-- Returns the rate of change in body temp
winter.body_temp_change_rate = function(player)
	return winter.body_heat_flow_rate(player) / winter.body_specific_heat / winter.default_body_mass
end


-- Returns the amount of heat flowing into the body, along with heat from metabolism
winter.body_heat_flow_rate = function(player)
	local external_temp = winter.get_cached(player, "feels_like_temp")
	local body_temp = player:get_meta():get_float("body_temperature")

	local temp_difference = external_temp - body_temp
	local thermal_conductivity = winter.thermal_conductivity(player)
	local surface_area = winter.body_surface_area
	local metabolism = winter.metabolism(player)

	return temp_difference * thermal_conductivity * surface_area + metabolism
end

winter.thermal_conductivity = function(player)
	-- Did you know you can use Ohm's law for heat transfer? Neither did I, but it's super cool!
	-- Basically instead of Voltage = Current * Resistance, it's Temperature Difference = Heat Flow * 1/Conductivity (I think)
	-- Now we can use all those fancy equations for series/parallel circuits, but for heat!

	-- Clothing on differen limbs is like a parallel circuit
	-- Depending on which limbs you have covered, there are different paths for the heat to take
	-- 1/R_total = 1/R1 + 1/R2 + ...
	-- => Conductivity_total = Conductivity1 + Conductivity2 +  ...

	-- However, layers of clothing (and treating the body/skin as a layer), it's also a series circuit
	-- R_total = R1 + R2 ...
	-- => 1/Conductivity_total = 1/Conductivity1 + 1/Conductivity2 +  ...
	-- => Conductivity_total = 1/(1/Conductivity1 + 1/Conductivity2 +  ...)

	-- We can also treat wetness as a parallel circuit, as if the water provides an alternative way for heat to escape (maybe that's wrong idk)
	local wetness = player:get_meta():get_float("wetness")
	local wetness_conductivity = wetness * winter.wetness_thermal_conductivity

	-- In essense, the overall circuit looks like this:
	-- -- Body/Skin in series with each limb (and water)
	-- -- Each limb (Head, Torso, Legs, Feet) in series with the different layers of clothing on it
	-- -- Each limb/water can be thought of as all in parallel with each other
	
	-- So the equation is like:
	-- 1 / R_total = 1 / (R_Body + R_Head) + 1 / (R_Body + R_Torso) + 1 / (R_Body + R_Legs) + + 1 / (R_Body + R_Feet) + + 1 / (R_Body + R_Water)
	-- => Conductivity_total = 1/(1/Body + 1/Head) + 1/(1/Body + 1/Torso) + 1/(1/Body + 1/Legs) + ...
	-- Check out clothing.lua for the exact implementation

	local clothing = winter.get_clothing(player)

	-- The function takes into account skin as the first layer of clothing
	-- And we are weighting these to give things like the torso more importance
	local clothing_conductivity = (
		winter.get_clothing_group_conductivity(clothing, "armor_head") * winter.head_conductivity_weight
		+ winter.get_clothing_group_conductivity(clothing, "armor_torso") * winter.torso_conductivity_weight
		+ winter.get_clothing_group_conductivity(clothing, "armor_legs") * winter.legs_conductivity_weight
		+ winter.get_clothing_group_conductivity(clothing, "armor_feet") * winter.feet_conductivity_weight
	)

	return clothing_conductivity + wetness_conductivity
end


winter.metabolism = function(player)
	local metabolism_rate = winter.default_metabolism_rate
	--return metabolism_rate
	local body_temp = player:get_meta():get_float("body_temperature")
	local temp_difference = winter.target_body_temperature - body_temp
	-- Offset by a bit to just make sure you're still makeing energy even if you're like 36.99 degrees
	return math.max(-metabolism_rate, math.min(metabolism_rate, metabolism_rate * (temp_difference + 0.3)))
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
