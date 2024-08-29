local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gorp = require(ReplicatedStorage.packages.gorp)
local loop_setup = require(ReplicatedStorage.shared.loop_setup)
local world = require(ReplicatedStorage.shared.world)

local client = ReplicatedStorage.client
local systems = client.systems

local order: { { interval: number } | string } = {
	{ interval = 1 },
	"replication/general_receive",
}

return loop_setup(world, systems, table.unpack(order))
