local vide = require("@packages/vide")

local cleanup = vide.cleanup
local derive = vide.derive
local effect = vide.effect
local source = vide.source

local BASE_RESOLUTION = Vector2.new(1920, 1080)
local DOMINANT_AXIS = 0.5

local currentScale = source(1)

local function modifyScale(scale: number): number
	return scale
end

local function usePx()
	local viewportSize = source(Vector2.new(0, 0))

	local getConstrainedViewportSize = derive(function()
		local viewport = viewportSize()
		local constrainedAspectRatio = math.min(viewport.X / viewport.Y, 16 / 9)
		return Vector2.new(viewport.Y * constrainedAspectRatio, viewport.Y)
	end)

	effect(function()
		local viewport = getConstrainedViewportSize()
		local scaleX = math.log(viewport.X / BASE_RESOLUTION.X, 2)
		local scaleY = math.log(viewport.Y / BASE_RESOLUTION.Y, 2)
		currentScale(modifyScale(2 ^ math.lerp(scaleX, scaleY, DOMINANT_AXIS)))
	end)

	cleanup(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewportSize(workspace.CurrentCamera.ViewportSize)
	end))

	viewportSize(workspace.CurrentCamera.ViewportSize)
end

local function setScale(scale: number)
	currentScale(scale)
end

local function px(x: number): () -> number
	return function()
		return math.round(x * currentScale())
	end
end

local function raw(scaled: number): number
	return math.round(scaled / currentScale())
end

local function scale(x: number): () -> number
	return function()
		return x * currentScale()
	end
end

local function offset(x: number, y: number): () -> UDim2
	return function()
		return UDim2.fromOffset(px(x)(), px(y)())
	end
end

local function udim2(xScale: number, xOffset: number, yScale: number, yOffset: number): () -> UDim2
	return function()
		return UDim2.new(xScale, px(xOffset)(), yScale, px(yOffset)())
	end
end

local function udim(s: number, o: number): () -> UDim
	return function()
		return UDim.new(s, px(o)())
	end
end

return setmetatable({
	usePx = usePx,
	setScale = setScale,
	raw = raw,
	scale = scale,
	offset = offset,
	udim2 = udim2,
	udim = udim,
}, {
	__call = function(_, value: number): () -> number
		return px(value)
	end,
})
