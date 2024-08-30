local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"

local _ct = require(ReplicatedStorage.shared.ct)
local gorp = require(ReplicatedStorage.packages.gorp)
local pv = require(ReplicatedStorage.shared.pv)
local server_loop = require(ServerScriptService.server.server_loop)
local world = require(ReplicatedStorage.shared.world)

gorp.names(pv :: any)
gorp.hook_world(world)

RunService.Heartbeat:Connect(function(dt)
	server_loop(dt)
end)
