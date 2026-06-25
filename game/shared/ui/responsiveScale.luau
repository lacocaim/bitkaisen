local DEFAULT_MARGIN_X = 28
local DEFAULT_MARGIN_Y = 70
local DEFAULT_MIN_SCALE = 0.34
local DEFAULT_MAX_SCALE = 1

local function attach(window, baseWidth, baseHeight, opts)
	local o = opts or {}
	local marginX = o.marginX or DEFAULT_MARGIN_X
	local marginY = o.marginY or DEFAULT_MARGIN_Y
	local minScale = o.minScale or DEFAULT_MIN_SCALE
	local maxScale = o.maxScale or DEFAULT_MAX_SCALE

	window.Size = UDim2.fromOffset(baseWidth, baseHeight)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.new(0.5, 0, 0.5, 0)

	local uiScale = window:FindFirstChild("ResponsiveScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "ResponsiveScale"
		uiScale.Parent = window
	end

	local function recompute()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local vp = camera.ViewportSize
		local sx = (vp.X - marginX) / baseWidth
		local sy = (vp.Y - marginY) / baseHeight
		uiScale.Scale = math.clamp(math.min(sx, sy, maxScale), minScale, maxScale)
	end

	local function bindCamera()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
		end
	end

	bindCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(function()
			bindCamera()
			recompute()
		end)
	end)
	recompute()

	return {
		uiScale = uiScale,
		recompute = recompute,
	}
end

return { attach = attach }
