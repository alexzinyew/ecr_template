local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local world = require(ReplicatedStorage.shared.world)
local zap = require(ReplicatedStorage.shared.zap)
local zapqueue = require(ReplicatedStorage.shared.zapqueue)

local client_ready = zapqueue(zap.client_ready)
local player_removing = ecr.queue(Players.PlayerRemoving)

return function(dt: number)
	local context = world:context()
	if not context:has(pv.ConnectedPlayers) then
		context:add(pv.ConnectedPlayers)
	end

	local connected = context:get(pv.ConnectedPlayers)

	-- add player to world and context
	for player in client_ready do
		if table.find(connected, player) then return end
		context:insert(pv.ConnectedPlayers, player)
	end

	for _, player in Players:GetPlayers() do
		if world:find(pv.Player, player) then continue end

		local entity = world:handle()
		entity:set(pv.Player, player)
	end

	-- remove player from world and context
	for player in player_removing do
		context:patch(pv.ConnectedPlayers, function(players)
			local i = table.find(players, player)
			if i then table.remove(players, i) end
			return players
		end)

		local id = world:find(pv.Player, player)
		if id then world:destroy(id) end
	end
end
