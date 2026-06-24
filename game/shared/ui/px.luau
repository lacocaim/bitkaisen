local vide = require("@packages/vide")

local source = vide.source

local BASE_RESOLUTION = Vector2.new(1920, 1080)
local DOMINANT_AXIS = 0.5

local currentScale = source(1)

local function recalcScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local constrainedAspectRatio = math.min(viewport.X / viewport.Y, 16 / 9)
	local constrained = Vector2.new(viewport.Y * constrainedAspectRatio, viewport.Y)
	local scaleX = math.log(constrained.X / BASE_RESOLUTION.X, 2)
	local scaleY = math.log(constrained.Y / BASE_RESOLUTION.Y, 2)
	currentScale(2 ^ math.lerp(scaleX, scaleY, DOMINANT_AXIS))
end

local function usePx()
	recalcScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recalcScale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(function()
			recalcScale()
			if workspace.CurrentCamera then
				workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recalcScale)
			end
		end)
	end)
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
