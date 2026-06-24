--[[
	Device-universal pixel scaling system.
	Adapted from anime-legacy-repo's px.luau for Fusion 0.2.

	Design at 1920x1080, call px.connectViewport() once at UI root,
	then use px(n) to get scaled Computed values for any pixel measurement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed

local BASE_RESOLUTION = Vector2.new(1920, 1080)
local DOMINANT_AXIS = 0.5

local currentScale = Value(1)
local connected = false

local function modifyScale(scale: number): number
	return scale
end

local function connectViewport()
	if connected then return end
	connected = true

	local camera = workspace.CurrentCamera
	if not camera then
		camera = workspace:WaitForChild("Camera") :: Camera
	end

	local function update()
		local viewport = camera.ViewportSize
		local constrainedAspectRatio = math.min(viewport.X / viewport.Y, 16 / 9)
		local constrained = Vector2.new(viewport.Y * constrainedAspectRatio, viewport.Y)

		local scaleX = math.log(constrained.X / BASE_RESOLUTION.X, 2)
		local scaleY = math.log(constrained.Y / BASE_RESOLUTION.Y, 2)

		currentScale:set(modifyScale(2 ^ math.lerp(scaleX, scaleY, DOMINANT_AXIS)))
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
end

local function px(x: number)
	return Computed(function()
		return math.round(x * currentScale:get())
	end)
end

local function raw(scaled: number): number
	return math.round(scaled / currentScale:get())
end

local function scale(x: number)
	return Computed(function()
		return x * currentScale:get()
	end)
end

local function offset(x: number, y: number)
	return Computed(function()
		local s = currentScale:get()
		return UDim2.fromOffset(math.round(x * s), math.round(y * s))
	end)
end

local function udim2(xScale: number, xOffset: number, yScale: number, yOffset: number)
	return Computed(function()
		local s = currentScale:get()
		return UDim2.new(xScale, math.round(xOffset * s), yScale, math.round(yOffset * s))
	end)
end

local function udim(scaleVal: number, offsetVal: number)
	return Computed(function()
		local s = currentScale:get()
		return UDim.new(scaleVal, math.round(offsetVal * s))
	end)
end

return setmetatable({
	connectViewport = connectViewport,
	setScale = function(s: number) currentScale:set(s) end,
	raw = raw,
	scale = scale,
	offset = offset,
	udim2 = udim2,
	udim = udim,
}, {
	__call = function(_, value: number)
		return px(value)
	end,
})
