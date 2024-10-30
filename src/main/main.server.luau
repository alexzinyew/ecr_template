local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"

-- stylua: ignore
local _ct = require(ReplicatedStorage.shared.ct)
local server_loop = require(ServerScriptService.server.server_loop)

RunService.Heartbeat:Connect(function(dt) server_loop(dt) end)
