local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local _ct = require(ReplicatedStorage.shared.ct)
local _main_ui = require(ReplicatedStorage.client.ui.main_ui)
local client_loop = require(ReplicatedStorage.client.client_loop)
local zap = require(ReplicatedStorage.shared.zap)

zap.player_ready.fire {}
RunService:BindToRenderStep("loop", 201, function(dt) client_loop(dt) end)
