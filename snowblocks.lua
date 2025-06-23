
winter.snow_trudging_temp_penalty = 0.1


local num_snow_heights = 4


if core.get_modpath("default") then
	-- Definition mostly copied from default/nodes.lua
	for i = 1,num_snow_heights do
		core.register_node("winter:snow" .. i, {
			description = "Snow " .. i,
			tiles = {"default_snow.png"},
			wield_image = "default_snowball.png",
			paramtype = "light",
			buildable_to = i ~= num_snow_heights,
			floodable = true,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = {
					{-0.5, -0.5, -0.5, 0.5, -0.5 + i / num_snow_heights, 0.5}
				}
			},
			collision_box = {
				type = "fixed",
				fixed = {
					-- Having a taller but thinner inner collision box to make it easier to climb like stairs
					{-0.4, -0.5, -0.4, 0.4, -0.3, 0.4},
					--{-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
				}
			},
			groups = {crumbly = 3, falling_node = 1, snowy = 1},
			sounds = default.node_sound_snow_defaults(),
			_tnt_loss = 1,
			move_resistance = (i - 1) / 2,

			drop = "winter:snowball",

			after_dig_node = function(pos)
				if i > 1 then
					minetest.set_node(pos, {name = "winter:snow" .. (i - 1)})
				end
			end
		})
	end

	core.register_craftitem("winter:snowball", {
		description = "Snow",
		inventory_image = "default_snowball.png",
		on_place = function(itemstack, placer, pointed_thing)
			local nodename = core.get_node(pointed_thing.under).name
			-- If placing on snow, make the snow taller
			if string.find(nodename, "winter:snow") then
				local nodenumber = tonumber(string.sub(nodename, -1))
				core.debug(nodename, nodenumber)
				if nodenumber < num_snow_heights then
					core.place_node(pointed_thing.under, {name = "winter:snow" .. (nodenumber + 1)}, placer)
					itemstack:take_item(1)
					return
				end
			end
			core.place_node(pointed_thing.above, {name = "winter:snow1"}, placer)
			itemstack:take_item(1)
		end
	})


	core.register_lbm({
		label = "Replace default snow with winter snow",
		name = "winter:replace_snow",
		nodenames = {"default:snow", "default:snowblock"},
		run_at_every_load = true,
		action = function(pos, node, dtime_s)
			if core.get_node(pos + vector.new(0,1,0)).name ~= "air" then return end
			local all_surrounding_nodes =
				((core.get_node(pos + vector.new(1,0,0)).name ~= "air") and 1 or 0)
				+ ((core.get_node(pos + vector.new(-1,0,0)).name ~= "air") and 1 or 0)
				+ ((core.get_node(pos + vector.new(0,0,1)).name ~= "air") and 1 or 0)
				+ ((core.get_node(pos + vector.new(0,0,-1)).name ~= "air") and 1 or 0)
			core.set_node(pos, {name = "winter:snow" .. math.max(1, math.min(4, all_surrounding_nodes))})
		end,
	})

	winter.register_timer("pack_snow", 0.25, function(dtime)
		for _, player in pairs(core.get_connected_players()) do
			local control = player:get_player_control()
			if control.up or control.down or control.left or control.right or control.jump then
				local nodename = core.get_node(player:get_pos()).name
				if string.find(nodename, "winter:snow") then
					local nodenumber = tonumber(string.sub(nodename, -1))
					if nodenumber > 1 then
						core.set_node(player:get_pos(), {name = "winter:snow" .. (nodenumber - 1)})
						-- Make the player a tiny bit colder
						-- TODO make this work with thermal constants
						player:get_meta():set_float("body_temperature", player:get_meta():get_float("body_temperature") - winter.snow_trudging_temp_penalty * dtime)
					end
				end
			end
		end
	end)
end