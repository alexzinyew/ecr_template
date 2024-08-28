local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ecrx = require(ReplicatedStorage.shared.ecrx)
local gorp = require(ReplicatedStorage.packages.gorp)

local client = ReplicatedStorage.client
local systems = client.systems

local scheduler = gorp.scheduler("client")
local client_loop = ecrx.gameloop(scheduler, {
	{ i = 1 },
	systems.replicate_receive,
})

return function(dt)
	client_loop(dt)
end
