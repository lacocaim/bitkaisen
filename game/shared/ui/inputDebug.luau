local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PREFIX = "[BK-INPUTDEBUG]"

local KNOWN_PREFIXES = { "BitKaisen", "Mobile", "Topbar" }

local function isKnownGui(name: string): boolean
	for _, prefix in KNOWN_PREFIXES do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local inputDebug = {}

local function fmt(v)
	if typeof(v) == "Vector2" then
		return string.format("%.0fx%.0f", v.X, v.Y)
	end
	return tostring(v)
end

function inputDebug.dumpScreenGuis()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)

	local hasMobileGui = playerGui:FindFirstChild("MobileGui") ~= nil
	local hasPCGui = playerGui:FindFirstChild("BitKaisenGui") ~= nil
	if hasMobileGui and hasPCGui then
		warn(PREFIX, "!! BOTH MobileGui AND BitKaisenGui exist -- cross-mode bleed detected!")
	end

	print(PREFIX, "=== ScreenGui dump === viewport:", fmt(viewport))

	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") then
			local tag = ""
			if not isKnownGui(child.Name) then
				tag = " [ORPHAN?]"
			end
			print(PREFIX, string.format(
				"  %s  Enabled=%s  DisplayOrder=%d%s",
				child:GetFullName(), tostring(child.Enabled), child.DisplayOrder, tag
			))

			for _, desc in child:GetDescendants() do
				if desc:IsA("GuiObject") and desc.Visible and desc.Active then
					local sz = desc.AbsoluteSize
					if sz.X > viewport.X * 0.8 and sz.Y > viewport.Y * 0.5 then
						print(PREFIX, string.format(
							"    !! FULL-SCREEN ACTIVE: %s (%s) size=%s bgTransparency=%.2f",
							desc:GetFullName(), desc.ClassName, fmt(sz), desc.BackgroundTransparency
						))
					end
				end
			end
		end
	end
	print(PREFIX, "=== end dump ===")
end

function inputDebug.hitTestAt(x, y)
	local objects = playerGui:GetGuiObjectsAtPosition(x, y)
	print(PREFIX, string.format("--- hit-test at (%d, %d) => %d objects ---", x, y, #objects))
	for i, obj in objects do
		local active = "?"
		pcall(function() active = tostring(obj.Active) end)
		print(PREFIX, string.format(
			"  [%d] %s (%s) Active=%s Visible=%s Size=%s BgTransp=%.2f",
			i, obj:GetFullName(), obj.ClassName, active,
			tostring(obj.Visible), fmt(obj.AbsoluteSize), obj.BackgroundTransparency
		))
		if i >= 12 then
			print(PREFIX, "  ... truncated")
			break
		end
	end
end

function inputDebug.init()
	if not RunService:IsStudio() then return end

	print(PREFIX, "Input debug active")
	inputDebug.dumpScreenGuis()

	task.delay(3, function()
		inputDebug.dumpScreenGuis()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		inputDebug.hitTestAt(math.floor(pos.X), math.floor(pos.Y))
	end)
end

return inputDebug
