--!nolint ImportUnused
--!nolint FunctionUnused
--!nolint LocalUnused
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)
local gorp = require(ReplicatedStorage.packages.gorp)
local pv = require(script.Parent.pv)

local component = ecr.component
local tag = ecr.tag

local function deep_copy(t)
	local clone = table.clone(t)

	for key, value in clone :: { [string]: any } do
		if type(value) == "table" then clone[key] = deep_copy(value) end
	end

	return clone
end

local function primitive<T>(value: T): T
	return ecr.component(function() return value end)
end

local function struct<T>(value: T): T
	return ecr.component(function() return deep_copy(value :: any) :: any end)
end

local function array<T>(): { [number]: T }
	return ecr.component(function() return table.create(1) end)
end

local components = ecr.name {
	player = component() :: Player,
	localplayer = tag(),
	players_map = struct {} :: { [Player]: ecr.entity },

	connected_players = array() :: { Player },
	connecting_players = array() :: { Player },
	connected = tag(),

	model = component() :: Model & { PrimaryPart: BasePart },
	transform = component() :: CFrame,
}

gorp.names(components :: any)

return table.freeze(components)
