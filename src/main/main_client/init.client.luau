local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local _ct = require(ReplicatedStorage.shared.ct)
local client_loop = require(ReplicatedStorage.client.client_loop)
local gorp = require(ReplicatedStorage.packages.gorp)
local pv = require(ReplicatedStorage.shared.pv)
local world = require(ReplicatedStorage.shared.world)
local zap = require(ReplicatedStorage.shared.zap)

local gorp_client = gorp.get_client()
gorp.names(pv :: any)
gorp.hook_world(world)
gorp_client.enabled(true)
gorp_client.gorp_selector()

zap.client_ready.fire()
RunService:BindToRenderStep("loop", 201, function(dt)
	client_loop(dt)
end)
