local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ecrx = require(ReplicatedStorage.shared.ecrx)
local gorp = require(ReplicatedStorage.packages.gorp)

local server = ServerScriptService.server
local systems = server.systems

local scheduler = gorp.scheduler("server")
local loop = ecrx.gameloop(scheduler, {
	{ i = 1 },
	systems.player,
	systems.replicate_send,
})

return function(dt)
	loop(dt)
end
