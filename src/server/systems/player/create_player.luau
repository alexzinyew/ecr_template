local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.shared.ct)
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)

return function(world, dt)
	local ctx = world:context()

	local player_added = ecr.queue(Players.PlayerAdded)
	local player_removing = ecr.queue(Players.PlayerRemoving)

	ctx:add(ct.players_map)

	return function()
		for player in player_added:iter() do
			local id = world:create()

			world:set(id, ct.player, player)

			local function add_player_to_map(map)
				map[player] = id
				return map
			end

			ctx:patch(ct.players_map, add_player_to_map)
		end
		player_added:clear()

		for player in player_removing:iter() do
			local function remove_player_from_map(map)
				local id = map[player]

				if not id then return map end

				world:destroy(id)
				map[player] = nil
				return map
			end

			ctx:patch(ct.players_map, remove_player_from_map)
		end
		player_removing:clear()
	end
end :: pv.System
