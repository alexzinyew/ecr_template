local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)

return function(world: pv.Registry)
	local players = ecr.queue(Players.PlayerAdded)
	local character_connections = {}

	return function()
		for player in players:iter() do
			table.insert(
				character_connections,
				player.CharacterAppearanceLoaded:Connect(function(character)
					for _, object in character:GetDescendants() do
						if object:IsA "BasePart" and object.Parent:IsA "Accessory" then object.CanQuery = false end
					end
				end)
			)
		end
	end
end
