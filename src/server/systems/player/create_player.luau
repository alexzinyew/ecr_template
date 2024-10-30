local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.shared.ct)
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local zap = require(ReplicatedStorage.shared.zap)
local zap_queue = require(ReplicatedStorage.shared.zap.zap_queue)

return function(world: pv.Registry)
	local ctx = world:context()

	local player_added = ecr.queue(Players.PlayerAdded)
	local player_removing = ecr.queue(Players.PlayerRemoving)
	local player_loaded = zap_queue(zap.player_ready)

	ctx:add(ct.players_map, ct.connected_players, ct.connecting_players)

	return function()
		local connected_players, connecting_players = ctx:get(ct.connected_players, ct.connecting_players)

		table.clear(connecting_players) -- Clear so players who just connected are the only ones in this component in the single frame

		for player in player_loaded:iter() do
			if table.find(connected_players, player) then continue end
			ctx:insert(ct.connected_players, player)
			ctx:insert(ct.connecting_players, player)

			for id, _player in world:view(ct.player) do
				if _player ~= player then continue end
				world:add(id, ct.connected)
			end
		end
		player_loaded:clear()

		for player in player_added:iter() do
			local id = world:create()
			world:set(id, ct.player, player)

			ctx:patch(ct.players_map, function(map)
				map[player] = id
				return map
			end)
		end
		player_added:clear()

		for player in player_removing:iter() do
			ctx:patch(ct.players_map, function(map)
				local id = map[player]

				if not id then return map end

				world:destroy(id)
				map[player] = nil
				return map
			end)
		end
		player_removing:clear()
	end
end :: pv.System
