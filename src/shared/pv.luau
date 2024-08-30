local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ecr = require(ReplicatedStorage.packages.ecr)

export type System = (world: ecr.Registry, dt: number, start: number) -> ...(dt: number, start: number) -> ()
export type entity = ecr.entity
export type Registry = ecr.Registry

export type WorldDiff = {
	changes: {
		[string]: {
			added_or_changed: {
				entities: { ecr.entity },
				values: { unknown },
			},
			removed: { ecr.entity },
		},
	},
	destroyed: { ecr.entity },
}

export type Result<T> = {
	result: true,
	value: T,
} | {
	result: false,
	reason: string,
}

local function result<T>(result: boolean, value: (T | string)?): Result<T>
	if result then
		return {
			result = true,
			value = value :: T,
		}
	else
		return {
			result = false,
			reason = value :: string,
		}
	end
end

return {
	result = result,
}
