local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local ecr = require(ReplicatedStorage.packages.ecr)
local ecrx = require(ReplicatedStorage.shared.ecrx)
local gorp = require(ReplicatedStorage.packages.gorp)

local server = ServerScriptService.server
local shared = ReplicatedStorage.shared.systems
local systems = server.systems

local scheduler = gorp.scheduler "server"
local world = ecr.registry()
gorp.hook_world(world)

local loop = ecrx.loop(scheduler, world, {
	{ i = 1 },
	systems.player.create_player,
	systems.player.canquery,

	{ i = 1 },
	systems.transform.update_transform,

	{ i = 1 },
	systems.replication.general_send,
	systems.replication.run_zap,
})

return loop
