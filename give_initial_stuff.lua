



core.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	core.debug(dump(inv:get_lists()))
	inv:add_item("main", "winter:hat")
	inv:add_item("main", "winter:coat")
	inv:add_item("main", "winter:pants")
	inv:add_item("main", "winter:boots")
end)