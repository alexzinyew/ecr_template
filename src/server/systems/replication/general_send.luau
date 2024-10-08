--!optimize 2
--!native
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ct = require(ReplicatedStorage.shared.ct)
local ecr = require(ReplicatedStorage.packages.ecr)
local serde = require(ReplicatedStorage.shared.serde)
local world = require(ReplicatedStorage.shared.world)
local zap = require(ReplicatedStorage.shared.zap)
local zap_queue = require(ReplicatedStorage.shared.zap.zap_queue)

local dont_replicate = {}
local add_only = {}
local udp = {}

local function diff_table(include: { string }?)
	local diff = {}
	do
		diff.changes = {}
		for cname in next, ct do
			if include and not table.find(include, cname) then continue end
			diff.changes[cname] = {
				added_or_changed = {
					entities = {},
					values = {},
				},
				removed = {},
			}
		end
		diff.destroyed = {}
	end

	return diff
end

local function delta_context()
	local context = world:context()

	local updated_ct = {} :: { [string]: { [ecr.entity]: unknown } }

	for cname, ctype in next, ct do
		local updated = {}
		updated_ct[cname] = updated

		if table.find(dont_replicate, cname) then continue end

		if ecr.is_tag(ctype) then
			world:on_add(ctype):connect(function(id)
				updated[id] = true
			end)
		else
			world:on_add(ctype):connect(function(id, value)
				updated[id] = value
			end)

			world:on_change(ctype):connect(function(id, value)
				updated[id] = value
			end)
		end

		if table.find(add_only, cname) then continue end

		world:on_remove(ctype):connect(function(id)
			updated[id] = "remove"
		end)
	end

	return function()
		local diff = diff_table()
		local udp_diff = diff_table(udp)

		for cname, updated in updated_ct do
			local is_tag = ecr.is_tag(ct[cname])
			local serialize = serde.ser[cname]

			for id, value in updated do
				local changes = diff.changes[cname]

				if value == "remove" then
					if world:contains(id) then
						table.insert(changes.removed, id)
					else
						table.insert(diff.destroyed, id)
					end
				else
					if table.find(udp, cname) then changes = udp_diff.changes[cname] end

					table.insert(changes.added_or_changed.entities, id)
					if not is_tag then
						table.insert(changes.added_or_changed.values, if serialize then serialize(value) else value)
					end
				end
			end
		end

		-- tcp diff
		if next(diff.changes) or next(diff.destroyed) then
			zap.replicate_world.fire_list(context:get(ct.connected_players), diff)
		end

		-- udp diff
		if next(udp_diff.changes) or next(udp_diff.destroyed) then
			zap.udp_replicate_world.fire_list(context:get(ct.connected_players), udp_diff)
		end

		for _, updated in updated_ct do
			table.clear(updated)
		end
	end
end

local function full_context(player: Player)
	local diff = diff_table()

	for cname, ctype in next, ct do
		local is_tag = ecr.is_tag(ctype)
		local serialize = serde.ser[cname]
		local changes = diff.changes[cname]

		if table.find(dont_replicate, cname) then continue end

		for id, value in world:view(ctype) do
			table.insert(changes.added_or_changed.entities, id)
			if not is_tag then
				table.insert(changes.added_or_changed.values, if serialize then serialize(value) else value)
			end
		end
	end

	zap.replicate_world.fire(player, diff)
end

local context = delta_context()

-- clients ready for initial context
local client_ready = zap_queue(zap.client_ready)

return function(dt: number)
	for player in client_ready do
		full_context(player)
	end

	context()
end
