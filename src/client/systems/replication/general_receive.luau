--!optimize 2
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.shared.ct)
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local serdes = require(ReplicatedStorage.shared.serde)
local zap = require(ReplicatedStorage.shared.zap)
local zap_queue = require(ReplicatedStorage.shared.zap.zap_queue)

local function pass_back<T>(value): T return value end

return function(world: pv.Registry)
	local general_replication = zap_queue(zap.general_replication)
	local despawn = zap_queue(zap.despawn_entity)

	local map_ctypes = {}

	for name, ctype in ct do
		map_ctypes[ctype] = name
	end

	return function()
		for changes in general_replication:iter() do
			local ctype = changes.ctype :: unknown
			local serializer = serdes[map_ctypes[ctype] :: string] or { deserialize = pass_back } :: never

			for i, id in changes.ids do
				local value = changes.values[i]

				if not world:contains(id) then world:create(id) end

				world:set(id, ctype, serializer.deserialize(value))
			end

			for i, id in changes.removing do
				if not world:contains(id) then continue end
				world:remove(id, ctype)
			end
		end

		for packet in despawn:iter() do
			for _, id in packet do
				if not world:contains(id) then continue end

				world:destroy(id)
			end
		end
	end
end
