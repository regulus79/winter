
local weather_noise;
-- You can only init noise when the mapgen env is ready, but for some reason that wasn't always the case with on_mods_loaded
-- So here I check every frame to see if it's loaded yet, and if so, generate the weather noise. Probably not ideal
core.register_globalstep(function()
	if not weather_noise then
		weather_noise = core.get_value_noise({
			offset = 0,
			scale = 1,
			spread = vector.new(1,1,1),
			seed = 0,
			octaves = 3,
			persistence = 0.7,
			lacunarity = 2,
		})
	end
end)


local random_intensity = function(period, seedish)
	if weather_noise then
		return weather_noise:get_2d({x = core.get_gametime() / period, y = seedish * 100})
	else
		return 0
	end
end

winter.general_weather_intensity = function(pos)
	return math.max(0, random_intensity(300, 0)^2 + pos.y / 50)
end

winter.wind = function(pos)
	return 10 * vector.new(math.cos(random_intensity(600, 2)), 0, math.cos(random_intensity(600, 2))) * winter.general_weather_intensity(pos)
end
winter.fog = function(pos)
	return math.max(10, 80 - 60 * winter.general_weather_intensity(pos))
end
winter.snowfall_density = function(pos)
	return math.max(0.1, 3 * winter.general_weather_intensity(pos))
end


winter.is_in_winter_storm = function(player)
	return winter.general_weather_intensity(player:get_pos()) > 1
end

-- Returns the current temperature due to weather variations/altitude at pos
-- Does not take into account the shelter, wind, or fire
winter.raw_outside_temperature = function(pos)
	local base_temp = -20 * winter.general_weather_intensity(pos)
	return base_temp
end



local update_sky = function(player)
	player:set_sky({
		type = "regular",
		clouds = false,
		sky_color = {
			day_sky = "#FFFFFF",
			day_horizon = "#FFFFFF",
			dawn_sky = "#AAAAAA",
			dawn_horizon = "#AAAAAA",
			night_sky = "#000000",
			night_horizon = "#000000",
			fog_sun_tint = "#FFFFFF",
			fog_moon_tint = "#FFFFFF",
			fog_tint_type = "custom",
		},
		fog = {
			fog_distance = winter.fog(player:get_pos())
		}
	})
	player:set_sun({
		visible = false,
		sunrise_visible = false,
	})
	player:set_moon({
		visible = false,
	})
	player:set_stars({
		visible = false,
	})
end




local player_particlespawners = {}


local update_snow_particles = function(player)
	if player_particlespawners[player:get_player_name()] then
		core.delete_particlespawner(player_particlespawners[player:get_player_name()])
	end
	local playerpos = player:get_pos()
	local wind = winter.wind(playerpos)
	local spawner_size = math.min(20, winter.fog(playerpos))
	local spawner_midheight = math.max(0, 10 - wind:length() * 0.6)
	local snow_fall_speed = 1.5
	player_particlespawners[player:get_player_name()] = core.add_particlespawner({
		amount = winter.snowfall_density(playerpos) * (spawner_size * spawner_size),
		exptime = 15,
		time = 0,
		collisiondetection = true,
		collision_removal = true,
		object_collision = true,
		playername = player:get_player_name(),
		texture = {
			name = "winter_snow_particle.png",
		},
		glow = 3,

		pos = {
			min = playerpos + vector.new(-spawner_size, spawner_midheight - 3, -spawner_size) - wind,
			max = playerpos + vector.new(spawner_size, spawner_midheight + 3, spawner_size) - wind,
		},
		vel = vector.new(0, -snow_fall_speed, 0) + wind,
		size = {
			min = 0.3,
			max = 1
		},
	})
end



core.register_on_joinplayer(function(player)
	update_sky(player)
	update_snow_particles(player)
end)



winter.register_timer("sky_and_particle_update", 1, function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		update_snow_particles(player)
		update_sky(player)
	end
end)
