local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local serde = require(ReplicatedStorage.shared.serde)
local world = require(ReplicatedStorage.shared.world)
local zap = require(ReplicatedStorage.shared.zap)
local zapqueue = require(ReplicatedStorage.shared.zapqueue)

local function diff_load(diff: pv.WorldDiff)
	-- process destroyed entities first
	for _, id in diff.destroyed do
		if not world:contains(id) then continue end
		world:destroy(id)
	end

	for cname, changes in diff.changes do
		local ctype = pv[cname]
		local is_tag = ecr.is_tag(ctype)
		local values = changes.added_or_changed.values
		local deserialize = serde.de[cname]

		for i, id in changes.added_or_changed.entities do
			-- create entity because it may not exist yet
			if not world:contains(id) then world:create(id) end

			if is_tag then
				world:add(id, ctype)
			else
				world:set(
					id,
					ctype,
					if deserialize then deserialize(values[i]) else values[i]
				)
			end
		end

		for _, id in changes.removed do
			world:remove(id, ctype)
		end
	end
end

local incoming_diff = zapqueue(zap.replicate_world)
local udp_incoming_diff = zapqueue(zap.udp_replicate_world)

return function(dt: number)
	for diff in incoming_diff do
		diff_load(diff)
	end

	for diff in udp_incoming_diff do
		diff_load(diff)
	end
end
