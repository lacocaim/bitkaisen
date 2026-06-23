-- ModuleScript: BK_RuntimeBridge
-- Location: ServerScriptService.BitKaisenServer
-- Purpose: Lets modular services safely access current player stats later.

local ServerStorage = game:GetService("ServerStorage")

local BK_RuntimeBridge = {}

function BK_RuntimeBridge.Init(context)
	local old = ServerStorage:FindFirstChild("BitKaisenRuntimeBridge")
	if old then
		old:Destroy()
	end

	local bridge = Instance.new("Folder")
	bridge.Name = "BitKaisenRuntimeBridge"
	bridge.Parent = ServerStorage

	local getStats = Instance.new("BindableFunction")
	getStats.Name = "GetStats"
	getStats.Parent = bridge

	local applyStatChanges = Instance.new("BindableFunction")
	applyStatChanges.Name = "ApplyStatChanges"
	applyStatChanges.Parent = bridge

	local refreshPlayer = Instance.new("BindableEvent")
	refreshPlayer.Name = "RefreshPlayer"
	refreshPlayer.Parent = bridge

	local savePlayer = Instance.new("BindableEvent")
	savePlayer.Name = "SavePlayer"
	savePlayer.Parent = bridge

	print("[BK_RuntimeBridge] Loaded.")
end

return BK_RuntimeBridge
