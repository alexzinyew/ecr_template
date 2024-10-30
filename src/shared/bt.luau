local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ecr = require(ReplicatedStorage.packages.ecr)

export type Node<T...> = (T...) -> unknown
export type Handle = ecr.Handle

local SUCCESS = true
local FAILURE = false
local RUNNING = {}

local bt = {}
bt.running = RUNNING

function bt.selector<T...>(children: { Node<T...> }): Node<T...>
	return function(...: T...)
		for _, node in children do
			local status = node(...)
			if status == true or status == RUNNING then return status end
		end
		return FAILURE
	end
end

function bt.sequence<T...>(children: { Node<T...> }): Node<T...>
	return function(...: T...)
		for _, node in children do
			local status = node(...)
			if not status or status == RUNNING then return status end
		end
		return SUCCESS
	end
end

function bt.NOT<T...>(node: Node<T...>): Node<T...>
	return function(...: T...)
		local status = node(...)
		if status == SUCCESS then
			return FAILURE
		elseif status == FAILURE then
			return SUCCESS
		else
			return RUNNING
		end
	end
end

return bt
