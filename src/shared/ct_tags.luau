--[[

This file is used to provide helper functions which lets you tag components to
change certain behavior that is applied across all components.

]]

local function creator_callback(arr: { [any]: true }): <T>(ctype: T) -> T
	return function(ctype)
		arr[ctype] = true
		return ctype
	end
end

local server_only = {}
local target_replication = {}

return table.freeze {
	--- This tag ensures that the component with this tag will never be replicated to the client
	server = creator_callback(server_only),
	--- This tag ensures that the component with this tag will only be replicated to certain clients
	target = creator_callback(target_replication),

	--- This is a table containing a list of all the components marked with `server`
	server_only = server_only,
	--- This is a table containing a list of all the components marked with `target`
	target_replication = target_replication,
}
