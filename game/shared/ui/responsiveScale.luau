local device = require("@ui-state/device")

local DEFAULT_MARGIN_X = 28
local DEFAULT_MARGIN_Y = 70
local DEFAULT_MIN_SCALE = 0.34
local DEFAULT_MAX_SCALE = 1

local MOBILE_MARGIN_X = 10
local MOBILE_MARGIN_Y = 20
local MOBILE_MIN_SCALE = 0.55

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
		local mobile = device.isMobileLayout()

		local mx = if mobile then MOBILE_MARGIN_X else marginX
		local my = if mobile then MOBILE_MARGIN_Y else marginY
		local floor = if mobile then math.max(minScale, MOBILE_MIN_SCALE) else minScale

		if mobile then
			local portrait = vp.Y > vp.X
			local effectiveW = baseWidth
			local effectiveH = baseHeight

			if portrait and baseWidth > baseHeight then
				local aspect = baseHeight / baseWidth
				effectiveW = math.max(vp.X - mx * 2, 300)
				effectiveH = effectiveW * aspect
			end

			local sx = (vp.X - mx * 2) / effectiveW
			local sy = (vp.Y - my * 2) / effectiveH
			local s = math.clamp(math.min(sx, sy, maxScale), floor, maxScale)

			window.Size = UDim2.fromOffset(effectiveW, effectiveH)
			uiScale.Scale = s
		else
			window.Size = UDim2.fromOffset(baseWidth, baseHeight)
			local sx = (vp.X - mx) / baseWidth
			local sy = (vp.Y - my) / baseHeight
			uiScale.Scale = math.clamp(math.min(sx, sy, maxScale), minScale, maxScale)
		end
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

	device.subscribe(function()
		recompute()
	end)

	recompute()

	return {
		uiScale = uiScale,
		recompute = recompute,
	}
end

return { attach = attach }
