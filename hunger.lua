

--
-- Basically this file deals with interfacing with other hunger mods
-- so that as your body does its metabolism and produces heat, it will use hunger
--

-- Assuming 12000 J per hunger point.
-- You could say like, you have 6000 Calories of food in your system, = 21504000 ish J
-- Divided between 20 hunger points is like 1500000 J/point
-- But that's for the real world, but since luanti is a faster pace, you can divide that by like 100
winter.hunger_per_metabolism = -1 / 15000


winter.apply_hunger = function() end

--
-- HungerNG
--

if core.get_modpath("hunger_ng") then
	core.log("'Hunger NG' detected, using that for winter metabolism")
	winter.apply_hunger = function(player, amount)
		hunger_ng.alter_hunger(player:get_player_name(), amount, "body heating")
	end
	-- Put the snowflake statbar above the hunger bar
	winter.cold_statbar_offset = {x = 24, y = -112}
end



--
-- Hunger with HUD Bar
--

if core.get_modpath("hbhunger") then
	core.log("'Hunger with HUD Bar' detected, using that for winter metabolism")
	winter.apply_hunger = function(player, amount)
		local playername = player:get_player_name()
		hbhunger.hunger[playername] = tonumber(hbhunger.hunger[playername]) + amount
		hbhunger.set_hunger_raw(player)
	end
end