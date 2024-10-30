local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ecr = require(ReplicatedStorage.packages.ecr)

local ID_SIZE = 4
assert(ID_SIZE == ecr.id_size)

type Array<T> = { T }
type Map<T, U> = { [T]: U }

type entity = number
type Registry = ecr.Registry
type Queue<T...> = ecr.Queue<T...>
type Pool<T> = { size: number, entities: buffer, values: Array<T> }

type CType = unknown
type CTypes = Map<string, CType>

export type System = (Registry, number) -> ...(number) -> ()

local is_tag = ecr.is_tag

local function merge<T, U>(cts1: T, cts2: U): T & U
	local cts = table.clone(cts1 :: T & {})

	for name, component in next, cts2 :: U & {} do
		if cts[name] then error("duplicate component " .. name) end
		cts[name] = component
	end

	return cts :: T & U & {}
end

export type RegistrySnapshot = {
	destroyed: buffer?,
	[string]: { -- ctype name
		set: buffer?,
		values: Array<unknown>?,
		removed: buffer?,
	},
}

local snapshot = {}
do
	local function clone_pool_ids<T>(pool: Pool<T>): buffer
		local b = buffer.create(pool.size * ID_SIZE)
		buffer.copy(b, 0, pool.entities, 0, pool.size * ID_SIZE)
		return b
	end

	type SerializeOptions = {
		serialize: ((unknown) -> unknown)?,
		replicate_add_only: boolean?,
	}

	type DeserializeOptions = {
		deserialize: ((unknown) -> unknown)?,
		filter: ((Registry, entity) -> boolean)?,
	}

	function snapshot.create(cts: CTypes, reg: Registry, opts: Map<string, SerializeOptions?>): RegistrySnapshot
		local diff = { destroyed = nil }

		for cname, ctype in cts do
			local options = opts[cname]

			local pool = reg:storage(ctype)
			local values = table.clone(pool.values)

			local serialize = options and options.serialize
			if serialize then
				for i, v in values do
					values[i] = serialize(v)
				end
			end

			diff[cname] = {
				set = clone_pool_ids(pool),
				values = values,
				removed = nil,
			}
		end

		return diff
	end

	local REMOVED = newproxy()

	function snapshot.diff_generator(cts: CTypes, reg: Registry, opts: Map<string, SerializeOptions?>): () -> RegistrySnapshot?
		local updated_ctypes = {} :: Map<CType, Map<entity, unknown>>

		for cname, ctype in cts do
			local options = opts[cname]

			local map = {}
			updated_ctypes[ctype] = map

			if is_tag(ctype) then
				reg:on_add(ctype):connect(function(id) map[id] = true end)
			else
				reg:on_add(ctype):connect(function(id, v) map[id] = v end)
			end

			local replicate_add_only = options and options.replicate_add_only
			if replicate_add_only == nil then replicate_add_only = false end

			if not replicate_add_only then
				reg:on_change(ctype):connect(function(id, v) map[id] = v end)
				reg:on_remove(ctype):connect(function(id) map[id] = REMOVED end)
			end
		end

		return function()
			local diff = {}

			local set_ids = {}
			local removed_ids = {}

			local destroyed_n = 0
			local destroyed_ids = {}

			for cname, ctype in cts do
				local options = opts[cname]

				local map = updated_ctypes[ctype]
				if next(map) == nil then continue end

				local set_values = {}
				local set_n = 0
				local removed_n = 0

				for id, v in map do
					if v ~= REMOVED then
						set_n += 1
						set_ids[set_n] = id
						set_values[set_n] = v
					elseif reg:contains(id) then
						removed_n += 1
						removed_ids[removed_n] = id
					else
						destroyed_n += 1
						destroyed_ids[destroyed_n] = id
					end
				end

				local serialize = options and options.serialize
				if serialize then
					for i, v in set_values do
						set_values[i] = serialize(v)
					end
				end

				diff[cname] = {
					set = set_n > 0 and ecr.array_to_buffer(set_ids, set_n) or nil,
					values = (set_n > 0 and not is_tag(ctype)) and set_values or nil,
					removed = removed_n > 0 and ecr.array_to_buffer(removed_ids, removed_n) or nil,
				}

				table.clear(map)
			end

			if destroyed_n > 0 then diff.destroyed = ecr.array_to_buffer(destroyed_ids, destroyed_n) end

			return next(diff) ~= nil and diff or nil
		end
	end

	function snapshot.load(cts: CTypes, reg: Registry, opts: Map<string, DeserializeOptions?>, diff: RegistrySnapshot)
		assert(not cts.destroyed, 'component name "destroyed" is reserved')
		local destroyed = diff.destroyed
		if destroyed then
			assert(buffer.len(destroyed) % ID_SIZE == 0)

			for i = 0, buffer.len(destroyed) - 1, ID_SIZE do
				local id = buffer.readu32(destroyed, i)
				if reg:contains(id) then reg:destroy(id) end
			end
		end

		for cname, updated in diff do
			local options = opts[cname]
			local filter = options and options.filter

			if cname == "destroyed" then continue end
			local ctype = cts[cname]
			if not ctype then continue end

			local set_ids = updated.set
			local set_values = updated.values
			local removed_ids = updated.removed

			if removed_ids then
				local removed_n = buffer.len(removed_ids)
				assert(removed_n % ID_SIZE == 0)

				for i = 0, removed_n - 1, ID_SIZE do
					local id = buffer.readu32(removed_ids, i)

					if reg:contains(id) then
						if filter and not filter(reg, id) then continue end
						reg:remove(id, ctype)
					else
						--reg:create(id) -- todo: needed?
						reg:force_create(id)
					end
				end
			end

			if set_ids then
				if is_tag(ctype) then set_values = {} end
				assert(set_values)

				local set_n = buffer.len(set_ids)
				assert(set_n % ID_SIZE == 0)

				local deserialize = options and options.deserialize
				if deserialize then
					for i, v in set_values do
						set_values[i] = deserialize(v)
					end
				end

				local j = 0
				for i = 0, set_n - 1, ID_SIZE do
					j += 1

					local id = buffer.readu32(set_ids, i)
					if not reg:contains(id) then reg:force_create(id) end

					if filter and not filter(reg, id) then continue end

					reg:set(id, ctype, set_values[j])
				end
			end
		end
	end
end

local function queue_old_values<T>(reg: Registry, ctype: T): Queue<T>
	local q = ecr.queue()

	local function listener(id) q:add(reg:try_get(id, ctype) :: T) end

	reg:on_change(ctype):connect(listener)
	reg:on_remove(ctype):connect(listener)

	return q
end

local function queue_old_entities_and_values<T>(reg: Registry, ctype: T): Queue<entity, T>
	local q = ecr.queue()

	local function listener(id) q:add(id, reg:get(id, ctype)) end

	reg:on_change(ctype):connect(listener)
	reg:on_remove(ctype):connect(listener)

	return q
end

local function entity_map<T>(reg: Registry, lifetime: unknown): Map<entity, T?>
	local map = {}

	reg:on_remove(lifetime):connect(function(id) map[id] = nil end)

	return map
end

type GroupInfo = { i: number?, o: number? }

type SystemGroup = {
	interval: number,
	offset: number,
	dt: number,
	[number]: {
		name: string,
		type: number,
		fn: (...any) -> ...any,
	},
}

local function run_sys(name: string, fn: (...unknown) -> (), ...: unknown)
	local thread = coroutine.create(function(...)
		local ok, err: string? = xpcall(fn, function(err: string)
			local trace = debug.traceback(nil, 2)
			return `ERROR:\n{err}\n\nTRACE:\n{trace}`
		end, ...)

		return ok, err
	end)

	local _, ok, result = coroutine.resume(thread, ...)

	if not ok then warn(`system "{name}" errored\n\n{result}`) end

	if coroutine.status(thread) == "suspended" then warn(`system "{name}" yielded`) end
end

local function loop_create(scheduler: any, reg: Registry, ...: ModuleScript | (Registry) -> () | GroupInfo): (number) -> ()
	local groups = {} :: Array<SystemGroup>

	local current_group: SystemGroup?

	local function process_systems(array: Array<any>)
		for i, v in array do
			if type(v) == "table" then
				if v.i then
					if current_group then table.insert(groups, current_group) end

					current_group = {
						interval = v.i or 1,
						offset = v.o or 0,
						dt = 0,
					}
				else
					process_systems(v)
				end
			elseif type(v) == "function" then
				assert(current_group)

				table.insert(current_group, {
					name = "UNNAMED",
					type = 0,
					fn = v,
				})
			else
				assert(current_group)

				local fn = (require :: any)(v) :: System
				local fn2 = fn(reg, 0)

				table.insert(current_group, {
					name = v.Name,
					type = fn2 and 1 or 0,
					fn = fn2 or fn,
				})
			end
		end
	end

	process_systems { ... }

	assert(current_group)
	table.insert(groups, current_group)
	current_group = nil

	local frame_count = 0

	return function(dt)
		frame_count += 1

		debug.profilebegin "ECS LOOP"

		for _, group in groups do
			group.dt += dt

			if frame_count % group.interval == group.offset then
				for _, system in ipairs(group) do
					debug.setmemorycategory(system.name)
					debug.profilebegin(system.name)
					local t_start = os.clock()

					if system.type == 0 then
						--run_sys(system.name, system.fn, reg, group.dt)
						scheduler:system(system.name, system.fn, reg, group.dt)
					else
						--run_sys(system.name, system.fn, group.dt)
						scheduler:system(system.name, system.fn, group.dt)
					end

					local t_stop = os.clock()
					if t_stop - t_start > 0.5 then warn(`{system.name} exceeded 500 ms runtime`) end

					debug.profileend()
				end

				group.dt = 0
			else
				for _, system in ipairs(group) do
					scheduler:skip(system.name)
				end
			end
		end

		scheduler:finish()
		debug.resetmemorycategory()
		debug.profileend()
	end
end

export type Set<T> = {
	size: number,
	sparse: Map<T, number?>,
	dense: Array<T>,

	add: (Set<T>, T) -> (),
	remove: (Set<T>, T) -> (),
	has: (Set<T>, T) -> (),
	clear: (Set<T>) -> (),
	iter: (Set<T>) -> () -> T,
}

local function set<T>(): Set<T>
	return {
		size = 0,
		sparse = {},
		dense = {},

		add = function(self: Set<T>, k: T)
			if self.sparse[k] ~= nil then return end

			local n = self.size + 1
			self.size = n
			self.sparse[k] = n
			self.dense[n] = k
		end,

		remove = function(self: Set<T>, k: T)
			local i = self.sparse[k]
			if i == nil then return end

			local n = self.size
			self.size = n - 1
			local last = self.dense[n]

			self.dense[i] = last
			self.dense[n] = nil

			self.sparse[last] = i
			self.sparse[k] = nil
		end,

		has = function(self: Set<T>, k: T) return self.sparse[k] ~= nil end,

		clear = function(self: Set<T>)
			self.size = 0
			table.clear(self.sparse)
			table.clear(self.dense)
		end,

		iter = function(self: Set<T>)
			local n = self.size
			return function()
				local i = n
				n = i - 1
				return self.dense[i]
			end
		end,
	}
end

type ISet<T> = {
	add: (ISet<T>, T) -> (),
}

local type = function<T>(ctor: (() -> T) | ISet<T>, ...: ISet<T>): T
	local ctype = (type(ctor) == "function" and ecr.component(ctor) or ecr.component()) :: T

	for _, set in { (type(ctor) ~= "function" and ctor or nil) :: ISet<T>, ... } do
		set:add(ctype)
	end

	return ctype
end :: (<T>(() -> T, ...ISet<T>) -> T) & (<T>(...ISet<T>) -> T)

local function tag<T>(...: ISet<nil>): nil
	local ctype = ecr.tag()

	for _, set in { ... } do
		set:add(ctype)
	end

	return ctype
end

return table.freeze {
	merge = merge,
	loop = loop_create,
	snapshot_create = snapshot.create,
	snapshot_diff_generator = snapshot.diff_generator,
	snapshot_load = snapshot.load,
	queue_old_values = queue_old_values,
	queue_old_entities_and_values = queue_old_entities_and_values,
	entity_map = entity_map,
	set = set,
	type = type,
	tag = tag,
}
