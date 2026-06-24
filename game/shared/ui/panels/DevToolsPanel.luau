local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local uiState = require("@ui-state/uiState")
local responsiveScale = require("@ui/responsiveScale")

local TESTING_PLACE_ID = 104206065947170

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Window = Color3.fromRGB(14, 16, 20),
	Card = Color3.fromRGB(24, 27, 34),
	Text = Color3.fromRGB(238, 240, 246),
	SubText = Color3.fromRGB(168, 174, 190),
	Gold = Color3.fromRGB(255, 205, 92),
	Blue = Color3.fromRGB(112, 180, 255),
	Green = Color3.fromRGB(110, 220, 150),
	Red = Color3.fromRGB(226, 82, 92),
	Purple = Color3.fromRGB(154, 95, 242),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenDevToolsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 643
gui.Enabled = false
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "DevToolsOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.ZIndex = 643
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "DevToolsWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = COLORS.Window
window.BorderSizePixel = 0
window.ZIndex = 644
window.Parent = overlay

local function makeCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function makeStroke(obj)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(65, 70, 86)
	s.Thickness = 1
	s.Transparency = 0.14
	s.Parent = obj
end

makeCorner(window, 10)
makeStroke(window)

local isOpen = false

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

local function openPanel()
	isOpen = true
	gui.Enabled = true
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

local function init()
	if game.PlaceId ~= TESTING_PLACE_ID then return end

	local getDevTools = ReplicatedStorage:WaitForChild("GetDevTools")
	local devToolsAction = ReplicatedStorage:WaitForChild("DevToolsAction")

	local ok, payload = pcall(function() return getDevTools:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" or payload.Allowed ~= true then return end

	local isCompactMobile = false
	local outerPad = isCompactMobile and 14 or 24
	local scrollTop = isCompactMobile and 58 or 66
	local scrollBottom = isCompactMobile and 74 or 90
	local clanColumns = isCompactMobile and 3 or 5
	local clanButtonWidth = isCompactMobile and 92 or 84
	local clanButtonGap = isCompactMobile and 8 or 8
	local clanButtonStep = clanButtonWidth + clanButtonGap
	local traitColumns = isCompactMobile and 1 or 2
	local traitColumnWidth = isCompactMobile and 0 or 245

	responsiveScale.attach(window, 1190, 821)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, outerPad, 0, isCompactMobile and 16 or 18)
	titleLabel.Size = UDim2.new(1, -(outerPad + 64), 0, 30)
	titleLabel.Text = "DEVELOPER TOOLS"
	titleLabel.TextColor3 = COLORS.Gold
	titleLabel.TextSize = isCompactMobile and 19 or 22
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 645
	titleLabel.Parent = window

	local closeBtn = Instance.new("TextButton")
	closeBtn.Position = UDim2.new(1, -(outerPad + 36), 0, isCompactMobile and 14 or 16)
	closeBtn.Size = UDim2.new(0, 38, 0, 34)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = COLORS.Red
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.BackgroundColor3 = Color3.fromRGB(34, 36, 45)
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 646
	closeBtn.Parent = window
	makeCorner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(function() uiState.closeRoute() end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.new(0, outerPad, 0, scrollTop)
	scroll.Size = UDim2.new(1, -(outerPad * 2), 1, -scrollBottom)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = isCompactMobile and 3 or 5
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 645
	scroll.Parent = window

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scroll

	local function makeText(parent, value, y, size, color, bold)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.new(0, 14, 0, y)
		t.Size = UDim2.new(1, -28, 0, 22)
		t.Text = value
		t.TextColor3 = color or COLORS.Text
		t.TextSize = size or 12
		t.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamMedium
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextWrapped = true
		t.ZIndex = parent.ZIndex + 1
		t.Parent = parent
		return t
	end

	local function card(titleText, height)
		local c = Instance.new("Frame")
		c.ClipsDescendants = true
		c.Size = UDim2.new(1, -8, 0, height)
		c.BackgroundColor3 = COLORS.Card
		c.BorderSizePixel = 0
		c.ZIndex = 645
		c.Parent = scroll
		makeCorner(c, 8)
		makeStroke(c)
		makeText(c, titleText, 12, 14, COLORS.Gold, true)
		return c
	end

	local function makeButton(parent, text, x, y, w, color, callback)
		local b = Instance.new("TextButton")
		b.Position = UDim2.new(0, x, 0, y)
		b.Size = UDim2.new(0, w, 0, 30)
		b.Text = text
		b.TextColor3 = COLORS.Text
		b.TextSize = 10
		b.Font = Enum.Font.GothamBlack
		b.BackgroundColor3 = color or Color3.fromRGB(42, 46, 58)
		b.BorderSizePixel = 0
		b.ZIndex = parent.ZIndex + 1
		b.Parent = parent
		makeCorner(b, 7)
		b.MouseButton1Click:Connect(callback)
		return b
	end

	local clans = payload.Clans or {}
	local clanRows = math.max(1, math.ceil(#clans / clanColumns))
	local clanCard = card("Clans", 48 + clanRows * 36)
	for index, clan in ipairs(clans) do
		local col = (index - 1) % clanColumns
		local row = math.floor((index - 1) / clanColumns)
		makeButton(clanCard, tostring(clan), 14 + col * clanButtonStep, 44 + row * 36, clanButtonWidth, COLORS.Blue, function()
			devToolsAction:FireServer("set_clan", { Clan = clan })
		end)
	end

	local statCard = card("Stat Modification", 162)
	local stats = { "CE", "Reputation", "Fame", "Fear" }
	for index, stat in ipairs(stats) do
		local y = 42 + (index - 1) * 30
		makeText(statCard, stat, y + 5, 11, COLORS.SubText, true)
		makeButton(statCard, "+1K", 132, y, 72, COLORS.Green, function()
			devToolsAction:FireServer("stat_delta", { Stat = stat, Amount = 1000 })
		end)
		makeButton(statCard, "-1K", 212, y, 72, COLORS.Red, function()
			devToolsAction:FireServer("stat_delta", { Stat = stat, Amount = -1000 })
		end)
	end

	local cursedTools = payload.CursedTools or {}
	local toolRows = math.max(1, math.ceil((#cursedTools + 1) / (isCompactMobile and 1 or 2)))
	local toolCard = card("Cursed Tools", math.max(122, 58 + toolRows * 38))
	makeText(toolCard, "Grant tools for inventory, mission, and combat testing.", 36, 11, COLORS.SubText, false)
	makeButton(toolCard, "GRANT ALL", 14, 64, 96, COLORS.Purple, function()
		devToolsAction:FireServer("grant_all_cursed_tools")
	end)
	for index, tool in ipairs(cursedTools) do
		local columns = isCompactMobile and 1 or 2
		local offsetIndex = index
		local col = (offsetIndex - 1) % columns
		local row = math.floor((offsetIndex - 1) / columns)
		local x = 14 + col * (isCompactMobile and 0 or 230)
		local y = 102 + row * 38
		local label = tostring(tool.Name or tool.Id or "Tool")
		makeButton(toolCard, label, x, y, isCompactMobile and 210 or 172, COLORS.Blue, function()
			devToolsAction:FireServer("grant_cursed_tool", { ToolId = tool.Id, Equip = true })
		end)
	end

	local warCard = card("Clan War Testing", 126)
	makeText(warCard, "Start or force clan war states for Update 13 testing.", 36, 11, COLORS.SubText, false)
	makeButton(warCard, "START WAR", 14, 68, 92, COLORS.Red, function()
		devToolsAction:FireServer("dev_start_clan_war")
	end)
	makeButton(warCard, "VICTORY", 116, 68, 82, COLORS.Green, function()
		devToolsAction:FireServer("dev_finish_clan_war", { Result = "Victory" })
	end)
	makeButton(warCard, "DEFEAT", 208, 68, 82, COLORS.Red, function()
		devToolsAction:FireServer("dev_finish_clan_war", { Result = "Defeat" })
	end)
	makeButton(warCard, "CLEAR", 300, 68, 76, COLORS.Blue, function()
		devToolsAction:FireServer("dev_clear_clan_war")
	end)

	local traits = payload.Traits or {}
	local traitRowHeight = isCompactMobile and 46 or 40
	local traitRows = math.max(1, math.ceil(#traits / traitColumns))
	local traitCard = card("Trait Editor", math.max(150, 62 + traitRows * traitRowHeight))
	makeText(traitCard, "Add or remove traits from the current life.", 36, 11, COLORS.SubText, false)
	for index, trait in ipairs(traits) do
		local col = (index - 1) % traitColumns
		local row = math.floor((index - 1) / traitColumns)
		local x = 14 + col * traitColumnWidth
		local y = 66 + row * traitRowHeight
		local addX = x + (isCompactMobile and 142 or 122)
		local removeX = x + (isCompactMobile and 202 or 182)
		local labelWidth = isCompactMobile and 126 or 108
		local traitLabel = makeText(traitCard, tostring(trait.Name or trait.Id), y, 10, COLORS.Text, true)
		traitLabel.Position = UDim2.new(0, x, 0, y)
		traitLabel.Size = UDim2.new(0, labelWidth, 0, isCompactMobile and 30 or 22)
		traitLabel.TextWrapped = false
		traitLabel.TextTruncate = Enum.TextTruncate.AtEnd
		traitLabel.TextXAlignment = Enum.TextXAlignment.Left
		makeButton(traitCard, "ADD", addX, y - 4, 54, COLORS.Green, function()
			devToolsAction:FireServer("add_trait", { TraitId = trait.Id })
		end)
		makeButton(traitCard, "REMOVE", removeX, y - 4, 64, COLORS.Red, function()
			devToolsAction:FireServer("remove_trait", { TraitId = trait.Id })
		end)
	end

	uiState.subscribe(function(route)
		if route == "dev" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
