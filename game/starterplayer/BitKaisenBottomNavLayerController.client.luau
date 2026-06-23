-- LocalScript: BitKaisenBottomNavLayerController
-- Purpose: Drops bottom navigation behind modal/minigame UI layers.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local navPanel = nil
local lastBlocked = nil

local function findNavPanel()
	if navPanel and navPanel.Parent then
		return navPanel
	end

	local bitKaisenGui = playerGui:FindFirstChild("BitKaisenGui")
	local mainPanel = bitKaisenGui and bitKaisenGui:FindFirstChild("MainPanel")
	navPanel = mainPanel and mainPanel:FindFirstChild("NavPanel") or playerGui:FindFirstChild("NavPanel", true)
	return navPanel
end

local function isEffectivelyVisible(guiObject)
	local current = guiObject
	while current and current ~= playerGui do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return true
end

local function hasActiveMinigame()
	local minigameGui = playerGui:FindFirstChild("BitKaisenMinigamesGui")
	if not (minigameGui and minigameGui:IsA("ScreenGui") and minigameGui.Enabled ~= false) then
		return false
	end

	for _, child in ipairs(minigameGui:GetChildren()) do
		if child:IsA("GuiObject") and isEffectivelyVisible(child) and child.AbsoluteSize.X > 100 and child.AbsoluteSize.Y > 80 then
			return true
		end
	end

	return false
end

local function hasBlockingModal()
	if hasActiveMinigame() then
		return true
	end

	local currentNav = findNavPanel()
	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiObject") and isEffectivelyVisible(descendant) and (not currentNav or not descendant:IsDescendantOf(currentNav)) then
			local name = tostring(descendant.Name or "")
			local isModalLayer = name:find("Overlay", 1, true) ~= nil or name:find("Window", 1, true) ~= nil or name:find("Minigame", 1, true) ~= nil
			if isModalLayer and descendant.AbsoluteSize.X > 100 and descendant.AbsoluteSize.Y > 80 then
				return true
			end
		end
	end

	return false
end

local function setStoredZIndex(object, zIndex)
	if not object or not object:IsA("GuiObject") then
		return
	end

	if object:GetAttribute("BitKaisenOriginalZIndex") == nil then
		object:SetAttribute("BitKaisenOriginalZIndex", object.ZIndex)
	end

	object.ZIndex = zIndex
end

local function restoreStoredZIndex(object)
	if not object or not object:IsA("GuiObject") then
		return
	end

	local original = object:GetAttribute("BitKaisenOriginalZIndex")
	object.ZIndex = typeof(original) == "number" and original or 1
end

local function applyNavLayer(blocked)
	local currentNav = findNavPanel()
	if not currentNav then
		return
	end

	if blocked then
		setStoredZIndex(currentNav, -20)
		for _, descendant in ipairs(currentNav:GetDescendants()) do
			setStoredZIndex(descendant, -20)
		end
	else
		restoreStoredZIndex(currentNav)
		for _, descendant in ipairs(currentNav:GetDescendants()) do
			restoreStoredZIndex(descendant)
		end
	end
end

RunService.RenderStepped:Connect(function()
	local blocked = hasBlockingModal()
	if blocked ~= lastBlocked then
		lastBlocked = blocked
		applyNavLayer(blocked)
	end
end)

playerGui.DescendantAdded:Connect(function(descendant)
	if navPanel and descendant:IsDescendantOf(navPanel) then
		task.defer(function()
			applyNavLayer(lastBlocked == true)
		end)
	end
end)

print("[BitKaisenBottomNavLayerController] Loaded bottom nav modal layering.")
