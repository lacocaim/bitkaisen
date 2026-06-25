local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModeSelect = require("@ui-components/shell/ModeSelect")
local loadingScreen = require("@ui/loadingScreen")

export type UIMode = "Computer" | "Mobile"

local _resolved = false
local _resolving = false
local _mode: UIMode? = nil
local _resolveEvent = Instance.new("BindableEvent")

local _initialStats: any = nil
local _initialMessage: any = nil
local _initialForceReset: any = nil

local function _readFromStats(stats: any): string?
	if typeof(stats) ~= "table" then return nil end
	if typeof(stats.Settings) ~= "table" then return nil end
	local m = stats.Settings.UIMode
	if m == "Computer" or m == "Mobile" then
		return m
	end
	return nil
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

	local ule = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 30)
	if not ule then
		_mode = "Computer"
		_resolved = true
		_resolving = false
		_resolveEvent:Fire()
		return "Computer"
	end

	local received = false
	local savedMode: string? = nil

	local conn
	conn = ule.OnClientEvent:Connect(function(updatedStats, logMessage, forceResetLog)
		if received then return end
		received = true
		savedMode = _readFromStats(updatedStats)
		_initialStats = updatedStats
		_initialMessage = logMessage
		_initialForceReset = forceResetLog
		conn:Disconnect()
	end)

	while not received do
		task.wait(0.05)
	end

	local picked = ModeSelect.prompt()

	loadingScreen.show(picked)

	_mode = picked
	_resolved = true
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
