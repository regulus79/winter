
local random_intensity = function(period, phase)
	return math.sin(2 * math.pi * core.get_us_time() / 1000000 / period + (phase or 0))
end

winter.wind = function(pos) return vector.new(2 + 2 * random_intensity(100),0,0) end
winter.fog = function(pos) return 55 + 50 * random_intensity(100, 1.5) end
winter.snowfall_density = function(pos) return 2 end



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
	local wind = winter.wind(player:get_pos())
	local spawner_size = math.min(20, winter.fog(pos))
	player_particlespawners[player:get_player_name()] = core.add_particlespawner({
		amount = winter.snowfall_density(pos) * (spawner_size * spawner_size),
		exptime = 15,
		time = 0,
		collisiondetection = true,
		collision_removal = true,
		object_collision = true,
		playername = player:get_player_name(),
		texture = {
			name = "default_snow.png",
		},
		glow = 3,

		pos = {
			min = player:get_pos() + vector.new(-spawner_size, 5, -spawner_size) - wind,
			max = player:get_pos() + vector.new(spawner_size, 10, spawner_size) - wind,
		},
		vel = vector.new(0, -1.5, 0) + wind,
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

local particle_update_timer = 0
local particle_update_period = 1
local weather_update_timer = 0
local weather_update_period = 1
core.register_globalstep(function(dtime)
	particle_update_timer = particle_update_timer + dtime
	weather_update_timer = weather_update_timer + dtime
	if particle_update_timer > particle_update_period then
		particle_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			update_snow_particles(player)
		end
	end
	if weather_update_timer > weather_update_period then
		weather_update_timer = 0
		for _, player in pairs(core.get_connected_players()) do
			update_sky(player)
		end
	end
end)