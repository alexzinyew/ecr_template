local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ct = require(ReplicatedStorage.shared.ct)

return function(world)
	local observer = world:track(ct.model, ct.transform)

	return function()
		for id, model, transform in observer do
			model:PivotTo(transform)
		end

		observer:disconnect()

		for id, model in world:view(ct.model):iter() do
			world:set(id, ct.transform, model:GetPivot())
		end

		observer:reconnect()
	end
end
