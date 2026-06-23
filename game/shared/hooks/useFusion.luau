local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local function useFusion()
	local scope = Fusion:scoped()

	return {
		scope = scope,
		Value = function(initial)
			return scope:Value(initial)
		end,
		Computed = function(callback)
			return scope:Computed(callback)
		end,
		Observer = function(target)
			return scope:Observer(target)
		end,
		Hydrate = function(target)
			return scope:Hydrate(target)
		end,
		New = function(className)
			return scope:New(className)
		end,
		cleanup = function()
			Fusion.doCleanup(scope)
		end,
	}
end

return useFusion
