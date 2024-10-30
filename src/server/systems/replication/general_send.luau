--!optimize 2
--!native

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.shared.ct)
local ct_tags = require(ReplicatedStorage.shared.ct_tags)
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local serde = require(ReplicatedStorage.shared.serde)
local zap = require(ReplicatedStorage.shared.zap)

return function(world: pv.Registry)
	local tracked_changes = {}

	for name, ctype in ct :: { [string]: unknown } do
		if ct_tags.server_only[ctype] then continue end

		tracked_changes[name] = {
			ctype = ctype,
			changes = {},
			removing = {},
		}

		world:on_add(ctype):connect(function(entity, value)
			tracked_changes[name].changes[entity] = value
			tracked_changes[name].removing[entity] = nil
		end)

		world:on_change(ctype):connect(function(entity, value)
			-- stops the same value from replicating
			if (type(value) ~= "table" and type(value) ~= "buffer") and world:get(entity, ctype) == value then return end
			tracked_changes[name].changes[entity] = value
		end)

		world:on_remove(ctype):connect(function(entity)
			tracked_changes[name].changes[entity] = nil
			tracked_changes[name].removing[entity] = true
		end)
	end

	return function()
		local destroying = {}
		local clients_connected, clients_connecting = world:context():get(ct.connected_players, ct.connecting_players)

		for name, changes in tracked_changes do
			--if ct_tags.target_replication[changes.ctype] then continue end
			local serializer = serde[name]

			local ctype = changes.ctype
			local entities = {}
			local values = {}
			local removing = {}

			for entity, value in changes.changes do
				table.insert(entities, entity)
				table.insert(values, value)
			end

			for entity in changes.removing do
				if world:contains(entity) == false then
					destroying[entity] = true
					continue
				end

				table.insert(removing, entity)
			end

			if serializer then
				for i, value in values do
					values[i] = serializer.serialize(value)
				end
			end

			changes.changes = {}
			changes.removing = {}

			if #entities == 0 and #removing == 0 then continue end

			zap.general_replication.fire_list(clients_connected, {
				ids = entities,
				values = values,
				removing = removing,
				-- ctypes are typed as the component value therefore unknown, but they're really just numbers.
				-- it'd be fine for us to just typecast it into a number in this case.
				ctype = ctype :: number,
			})
		end

		if next(destroying) then
			local destroying_arr = {}

			for ent in destroying do
				table.insert(destroying_arr, ent)
			end

			zap.despawn_entity.fire_list(clients_connected, destroying_arr)
		end

		if #clients_connecting == 0 then return end

		for name, changes in tracked_changes do
			local serializer = serde[name]

			local ctype = changes.ctype
			local pool = world:storage(ctype)

			local entities = ecr.buffer_to_array(pool.entities, pool.size)
			local values = table.clone(pool.values) :: { [number]: unknown }

			if serializer then
				for i, value in values do
					values[i] = serializer.serialize(value)
				end
			end

			if #entities == 0 then continue end
			zap.general_replication.fire_list(clients_connecting, {
				ids = entities,
				values = values,
				removing = {},
				-- ctypes are typed as the component value therefore unknown, but they're really just numbers.
				-- it'd be fine for us to just typecast it into a number in this case.
				ctype = ctype :: number,
			})
		end
	end
end
