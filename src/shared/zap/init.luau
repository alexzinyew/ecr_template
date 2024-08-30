local RunService = game:GetService "RunService"

type Server = typeof(require(script.zap_server))
type Client = typeof(require(script.zap_client))

return (if RunService:IsServer() then require(script.zap_server) else require(script.zap_client)) :: Server & Client
