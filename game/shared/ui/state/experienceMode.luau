local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local loadingScreen = require("@ui/loadingScreen")

export type UIMode = "Computer" | "Mobile"

local _resolved = false
local _resolving = false
local _mode: UIMode? = nil
local _resolveEvent = Instance.new("BindableEvent")

local _initialStats: any = nil
local _initialMessage: any = nil
local _initialForceReset: any = nil

-- Auto-detect the device class. Phones/tablets are touch-only (no physical
-- mouse + keyboard); we also treat any touch device with a small/portrait
-- viewport as Mobile so touch laptops/2-in-1s in tablet mode get the mobile UI.
local function detectMode(): UIMode
	if UserInputService.TouchEnabled
		and not UserInputService.MouseEnabled
		and not UserInputService.KeyboardEnabled
	then
		return "Mobile"
	end

	if UserInputService.TouchEnabled then
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		if vp.X < 900 or vp.Y > vp.X then
			return "Mobile"
		end
	end

	return "Computer"
end

-- Capture the first life event so the matching shell can render a populated
-- first frame. Runs while the loading screen is already covering the boot.
local function captureInitialLifeEvent()
	local ule = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 30)
	if not ule then return end

	local received = false
	local conn
	conn = ule.OnClientEvent:Connect(function(updatedStats, logMessage, forceResetLog)
		if received then return end
		received = true
		_initialStats = updatedStats
		_initialMessage = logMessage
		_initialForceReset = forceResetLog
		if conn then conn:Disconnect() end
	end)

	local startedAt = os.clock()
	while not received and (os.clock() - startedAt) < 10 do
		task.wait(0.05)
	end
end

local function resolve(): UIMode
	if _resolved then
		return _mode :: UIMode
	end

	if _resolving then
		_resolveEvent.Event:Wait()
		return _mode :: UIMode
	end
	_resolving = true

	local picked = detectMode()
	_mode = picked
	_resolved = true

	-- Show the device-specific loading screen immediately (no picker).
	loadingScreen.show(picked)

	captureInitialLifeEvent()

	-- Persist the detected mode so the server/record stays in sync.
	local evt = ReplicatedStorage:FindFirstChild("UpdateSettingsEvent")
	if evt then
		(evt :: RemoteEvent):FireServer("UIMode", picked)
	end

	_resolving = false
	_resolveEvent:Fire()
	return picked
end

local function get(): UIMode?
	return _mode
end

local function isResolved(): boolean
	return _resolved
end

local function waitForResolution(): UIMode
	if _resolved then return _mode :: UIMode end
	_resolveEvent.Event:Wait()
	return _mode :: UIMode
end

local function setMode(mode: UIMode)
	_mode = mode
	_resolved = true
	local evt = ReplicatedStorage:FindFirstChild("UpdateSettingsEvent")
	if evt then
		(evt :: RemoteEvent):FireServer("UIMode", mode)
	end
end

local function getInitialLifeEvent()
	return _initialStats, _initialMessage, _initialForceReset
end

return {
	resolve = resolve,
	get = get,
	isResolved = isResolved,
	waitForResolution = waitForResolution,
	setMode = setMode,
	getInitialLifeEvent = getInitialLifeEvent,
}
