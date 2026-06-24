local ripple = require("@packages/ripple")
local vide = require("@packages/vide")

local function tween<T>(initial: () -> T, options: ripple.TweenOptions<T>?): (() -> T, ripple.Tween<T>)
	local createdTween = ripple.createTween(initial(), options)
	local newValue = vide.source(initial())

	if not (options and options.start == false) then
		createdTween:start()
	end
	local disconnect = createdTween:onChange(newValue)

	vide.cleanup(function()
		disconnect()
		createdTween:destroy()
	end)
	vide.effect(function()
		createdTween:setGoal(initial())
	end)

	return newValue, createdTween
end

return tween
