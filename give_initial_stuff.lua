


--[[
core.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	core.debug(dump(inv:get_lists()))
	if core.get_modpath("3d_armor") then
		inv:add_item("main", "winter:hat")
		inv:add_item("main", "winter:coat")
		inv:add_item("main", "winter:pants")
		inv:add_item("main", "winter:boots")
	end
	if core.get_modpath("tcj_clothing") then
		inv:add_item("main", "tcj_clothing:hat")
		inv:add_item("main", "tcj_clothing:coat")
		inv:add_item("main", "tcj_clothing:pants")
		inv:add_item("main", "tcj_clothing:boots")
	end
end)
]]