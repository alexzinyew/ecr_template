local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ecr = require(ReplicatedStorage.packages.ecr)
local pv = require(ReplicatedStorage.shared.pv)
local vide = require(ReplicatedStorage.packages.vide)

local store = {}

store.npcs = vide.source({} :: { ecr.Handle })

return store
