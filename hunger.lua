

--
-- Basically this file deals with interfacing with other hunger mods
-- so that as your body does its metabolism and produces heat, it will use hunger
--

winter.hunger_per_metabolism = -0.25


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