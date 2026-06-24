local UserInputService = game:GetService("UserInputService")

local vide = require("@packages/vide")

local source = vide.source

export type FormFactor = "phone" | "tablet" | "desktop"
export type UiMode = "CrossPlatform" | "Mobile"

local PHONE_MAX_SHORT_EDGE = 600
local TABLET_MAX_SHORT_EDGE = 1100

local _platform = source("desktop" :: FormFactor)
local _isPortrait = source(false)
local _isTouchPrimary = source(false)
local _uiMode = source("CrossPlatform" :: UiMode)
local _uiModeOverridden = false
local _version = source(0)

local subscribers = {} :: { (mode: UiMode) -> () }

local function notifySubscribers()
	local mode = _uiMode()
	for _, fn in subscribers do
		task.spawn(fn, mode)
	end
end

local function subscribe(fn: (mode: UiMode) -> ()): () -> ()
	table.insert(subscribers, fn)
	return function()
		for i, sub in subscribers do
			if sub == fn then
				table.remove(subscribers, i)
				return
			end
		end
	end
end

local function detectTouchPrimary(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function computeFormFactor(viewport: Vector2): FormFactor
	local shortEdge = math.min(viewport.X, viewport.Y)
	if shortEdge <= PHONE_MAX_SHORT_EDGE then
		return "phone"
	elseif shortEdge <= TABLET_MAX_SHORT_EDGE then
		return "tablet"
	end
	return "desktop"
end

local function recompute()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize

	_isTouchPrimary(detectTouchPrimary())
	_isPortrait(viewport.Y > viewport.X)
	_platform(computeFormFactor(viewport))

	if not _uiModeOverridden then
		local autoMode: UiMode = if _isTouchPrimary() and _platform() ~= "desktop"
			then "Mobile"
			else "CrossPlatform"
		_uiMode(autoMode)
	end

	_version(_version() + 1)
	notifySubscribers()
end

local function setUiMode(mode: UiMode)
	_uiModeOverridden = true
	_uiMode(mode)
	_version(_version() + 1)
	notifySubscribers()
end

local function clearOverride()
	_uiModeOverridden = false
	recompute()
end

local function isMobileLayout(): boolean
	return _uiMode() == "Mobile"
end

local function init()
	recompute()

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
end

return {
	platform = _platform,
	isPortrait = _isPortrait,
	isTouchPrimary = _isTouchPrimary,
	uiMode = _uiMode,
	version = _version,

	isMobileLayout = isMobileLayout,
	setUiMode = setUiMode,
	clearOverride = clearOverride,
	subscribe = subscribe,
	recompute = recompute,
	init = init,
}
