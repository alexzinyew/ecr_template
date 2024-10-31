local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)
local ecrx = require(ReplicatedStorage.shared.ecrx)
local gorp = require(ReplicatedStorage.packages.gorp)

local client = ReplicatedStorage.client
local shared = ReplicatedStorage.shared.systems
local systems = client.systems

local scheduler = gorp.scheduler "client"
local world = ecr.registry()
local gorp_client = gorp.get_client()
gorp.hook_world(world)
gorp_client.enabled(true)
gorp_client.gorp_selector()

local loop = ecrx.loop(scheduler, world, {
	{ i = 1 },
	systems.replication.general_receive,

	{ i = 1 },
	systems.player.create_localplayer,

	{ i = 1 },
	shared.replication.run_zap,
})

return loop
