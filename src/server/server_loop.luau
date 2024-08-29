local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local loop_setup = require(ReplicatedStorage.shared.loop_setup)
local world = require(ReplicatedStorage.shared.world)

local server = ServerScriptService.server
local systems = server.systems

local order: { { interval: number } | string } = {
	{ interval = 1 },
	"player/create_player",

	{ interval = 1 },
	"replication/general_send",
}

return loop_setup(world, systems, table.unpack(order))
