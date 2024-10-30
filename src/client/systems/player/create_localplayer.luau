local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ct = require(ReplicatedStorage.shared.ct)
local pv = require(ReplicatedStorage.shared.pv)

local localplayer = Players.LocalPlayer

return function(world: pv.Registry)
	return function()
		for id, player in world:view(ct.player):iter() do
			if player ~= localplayer then continue end

			if not world:has(id, ct.model) and localplayer.Character then
				world:set(id, ct.model, localplayer.Character)
			elseif not localplayer.Character then
				world:remove(id, ct.model)
			end
		end
	end
end
