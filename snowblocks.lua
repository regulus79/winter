
winter.snow_trudging_temp_penalty = 0.1


local num_snow_heights = 4

local has_default = core.get_modpath("default")

-- Definition mostly copied from default/nodes.lua
for i = 1,num_snow_heights do
	core.register_node("winter:snow" .. i, {
		description = "Snow " .. i,
		tiles = {has_default and "default_snow.png" or "tcj_snow1.png"},
		wield_image = has_default and "default_snowball.png" or "",
		paramtype = "light",
		buildable_to = i ~= num_snow_heights,
		floodable = i ~= num_snow_heights,
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
		groups = has_default
			and {crumbly = 3, falling_node = 1, snowy = 1}
			or {shovelable = 1, falling_node = 1, snowy = 1},
		sounds = has_default and default.node_sound_snow_defaults() or nil,
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
	description = "Snowball",
	inventory_image = "winter_snowball.png",
	on_place = function(itemstack, placer, pointed_thing)
		local nodename = core.get_node(pointed_thing.under).name
		-- If placing on snow, make the snow taller
		if string.find(nodename, "winter:snow") then
			local nodenumber = tonumber(string.sub(nodename, -1))
			core.debug(nodename, nodenumber)
			if nodenumber < num_snow_heights then
				core.place_node(pointed_thing.under, {name = "winter:snow" .. (nodenumber + 1)}, placer)
				itemstack:take_item(1)
				return itemstack
			end
		end
		core.place_node(pointed_thing.above, {name = "winter:snow1"}, placer)
		itemstack:take_item(1)
		return itemstack
	end,
	on_use = function(itemstack, user)
		local obj = core.add_entity(user:get_pos() + vector.new(0, 1.7, 0) + 0.5 * user:get_look_dir(), "winter:snowball_entity", user:get_player_name())
		obj:set_velocity(user:get_look_dir() * 15 + user:get_velocity())
		itemstack:take_item(1)
		return itemstack
	end
})

-- Node to be added by mapgen, but replaced by real snow by lbm/abm
core.register_node("winter:temp_snow", {
	tiles = {has_default and "default_snow.png" or "tcj_snow1.png"},
})

-- LBMs are not super reliable with mapgen stuff, so I may have to resort to using an abm
local lbm_abm_def = {
	label = "Replace default snow with winter snow",
	name = "winter:replace_snow",
	nodenames = {"default:snow", "default:snowblock", "winter:temp_snow"},
	run_at_every_load = true,
	interval = 10,
	chance = 1,
	action = function(pos)
		if core.get_node(pos + vector.new(0,1,0)).name ~= "air" then return end
		local all_surrounding_nodes =
			((core.get_node(pos + vector.new(1,0,0)).name ~= "air") and 1 or 0)
			+ ((core.get_node(pos + vector.new(-1,0,0)).name ~= "air") and 1 or 0)
			+ ((core.get_node(pos + vector.new(0,0,1)).name ~= "air") and 1 or 0)
			+ ((core.get_node(pos + vector.new(0,0,-1)).name ~= "air") and 1 or 0)
		core.set_node(pos, {name = "winter:snow" .. math.max(1, math.min(4, all_surrounding_nodes))})
	end,
}
core.register_lbm(lbm_abm_def)
core.register_abm(lbm_abm_def)

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





--
-- Throwable snowballs :D
--

core.register_entity("winter:snowball_entity", {
	initial_properties = {
		visual = "sprite",
		textures = {"winter_snowball.png"},
		visual_size = vector.new(0.5, 0.5, 0.5),
		pointable = false,
		physical = true,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		use_texture_alpha = true,
		collide_with_objects = false,
	},
	on_activate = function(self, staticdata)
		self.player_name = staticdata
		self.object:set_acceleration(vector.new(0, -10, 0) + winter.wind(self.object:get_pos()))
	end,
	on_step = function(self, dtime, moveresult)
		if moveresult.collisions then
			for _, collision in pairs(moveresult.collisions) do
				if collision.type == "node" then
					--if core.get_node(collision.new_pos).name == "air" then
					local hit_pos = collision.new_pos
					local node_pos = collision.node_pos
					local axis
					if collision.axis == "x" then axis = vector.new(hit_pos.x < node_pos.x and 1 or 0, 0, 0) end
					if collision.axis == "y" then axis = vector.new(0, -1, 0) end
					if collision.axis == "z" then axis = vector.new(0, 0, hit_pos.z < node_pos.z and 1 or 0) end
					local under = node_pos
					local above = node_pos - axis
					core.debug(ItemStack("winter:snowball"), core.get_player_by_name(self.player_name), dump({under = under, above = above}))
					core.registered_craftitems["winter:snowball"].on_place(ItemStack("winter:snowball"), core.get_player_by_name(self.player_name), {under = under, above = above})
					self.object:remove()
					return
				end
			end
		end
	end
})