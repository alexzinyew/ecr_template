local ReplicatedStorage = game:GetService "ReplicatedStorage"
local zap = require(ReplicatedStorage.shared.zap)

local time_spent = 0
return function(_, dt)
	time_spent += dt

	if time_spent < 1 / 60 then return end
	time_spent = 0

	zap.send_events()
end
