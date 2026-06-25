local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TESTING_PLACE_ID = 104206065947170

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function buildContent(payload, devToolsAction)
	clearList()

	local clans = payload.Clans or {}
	if #clans > 0 then
		local clanCard = mc.mobileCard({ parent = scroll, order = 1 })
		mc.mobileLabel({
			parent = clanCard,
			text = "CLANS",
			size = 15,
			color = theme.Gold,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = clanCard,
			text = "Tap a clan to set it on this life.",
			size = 13,
			color = theme.SubText,
			order = 2,
		})

		local grid = Instance.new("Frame")
		grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y
		grid.BackgroundTransparency = 1
		grid.LayoutOrder = 3
		grid.Parent = clanCard

		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.new(0.48, 0, 0, 44)
		gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = grid

		for idx, clan in ipairs(clans) do
			mc.mobileButton({
				parent = grid,
				text = tostring(clan),
				size = UDim2.new(1, 0, 0, 44),
				position = UDim2.new(0, 0, 0, 0),
				color = theme.Blue,
				textSize = 13,
				order = idx,
				callback = function()
					devToolsAction:FireServer("set_clan", { Clan = clan })
				end,
			})
		end
	end

	local stats = { "CE", "Reputation", "Fame", "Fear" }
	local statCard = mc.mobileCard({ parent = scroll, order = 2 })
	mc.mobileLabel({
		parent = statCard,
		text = "STAT MODIFICATION",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	for idx, stat in ipairs(stats) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundTransparency = 1
		row.LayoutOrder = idx + 1
		row.Parent = statCard

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.4, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = stat
		label.TextColor3 = theme.Text
		label.TextSize = 14
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		mc.mobileButton({
			parent = row,
			text = "+1K",
			size = UDim2.new(0, 72, 0, 44),
			position = UDim2.new(1, -152, 0, 2),
			color = theme.Green,
			textColor = theme.Bg,
			textSize = 14,
			callback = function()
				devToolsAction:FireServer("stat_delta", { Stat = stat, Amount = 1000 })
			end,
		})

		mc.mobileButton({
			parent = row,
			text = "-1K",
			size = UDim2.new(0, 72, 0, 44),
			position = UDim2.new(1, -72, 0, 2),
			color = theme.Bad,
			textSize = 14,
			callback = function()
				devToolsAction:FireServer("stat_delta", { Stat = stat, Amount = -1000 })
			end,
		})
	end

	local cursedTools = payload.CursedTools or {}
	if #cursedTools > 0 then
		local toolCard = mc.mobileCard({ parent = scroll, order = 3 })
		mc.mobileLabel({
			parent = toolCard,
			text = "CURSED TOOLS",
			size = 15,
			color = theme.Gold,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = toolCard,
			text = "Grant tools for inventory, mission, and combat testing.",
			size = 13,
			color = theme.SubText,
			order = 2,
		})

		mc.mobileButton({
			parent = toolCard,
			text = "GRANT ALL",
			color = theme.Purple,
			order = 3,
			callback = function()
				devToolsAction:FireServer("grant_all_cursed_tools")
			end,
		})

		for idx, tool in ipairs(cursedTools) do
			mc.mobileButton({
				parent = toolCard,
				text = tostring(tool.Name or tool.Id or "Tool"),
				color = theme.Blue,
				textSize = 13,
				order = idx + 3,
				callback = function()
					devToolsAction:FireServer("grant_cursed_tool", { ToolId = tool.Id, Equip = true })
				end,
			})
		end
	end

	local warCard = mc.mobileCard({ parent = scroll, order = 4 })
	mc.mobileLabel({
		parent = warCard,
		text = "CLAN WAR TESTING",
		size = 15,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = warCard,
		text = "Start or force clan war states for testing.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	mc.mobileButton({
		parent = warCard,
		text = "START WAR",
		color = theme.Bad,
		order = 3,
		callback = function()
			devToolsAction:FireServer("dev_start_clan_war")
		end,
	})
	mc.mobileButton({
		parent = warCard,
		text = "VICTORY",
		color = theme.Green,
		textColor = theme.Bg,
		order = 4,
		callback = function()
			devToolsAction:FireServer("dev_finish_clan_war", { Result = "Victory" })
		end,
	})
	mc.mobileButton({
		parent = warCard,
		text = "DEFEAT",
		color = theme.Bad,
		order = 5,
		callback = function()
			devToolsAction:FireServer("dev_finish_clan_war", { Result = "Defeat" })
		end,
	})
	mc.mobileButton({
		parent = warCard,
		text = "CLEAR",
		color = theme.Blue,
		order = 6,
		callback = function()
			devToolsAction:FireServer("dev_clear_clan_war")
		end,
	})

	local traits = payload.Traits or {}
	if #traits > 0 then
		local traitCard = mc.mobileCard({ parent = scroll, order = 5 })
		mc.mobileLabel({
			parent = traitCard,
			text = "TRAIT EDITOR",
			size = 15,
			color = theme.Gold,
			font = Enum.Font.GothamBlack,
			order = 1,
		})
		mc.mobileLabel({
			parent = traitCard,
			text = "Add or remove traits from the current life.",
			size = 13,
			color = theme.SubText,
			order = 2,
		})

		for idx, trait in ipairs(traits) do
			local traitRow = Instance.new("Frame")
			traitRow.Size = UDim2.new(1, 0, 0, 48)
			traitRow.BackgroundTransparency = 1
			traitRow.LayoutOrder = idx + 2
			traitRow.Parent = traitCard

			local traitLabel = Instance.new("TextLabel")
			traitLabel.Size = UDim2.new(1, -156, 1, 0)
			traitLabel.BackgroundTransparency = 1
			traitLabel.Text = tostring(trait.Name or trait.Id)
			traitLabel.TextColor3 = theme.Text
			traitLabel.TextSize = 13
			traitLabel.Font = Enum.Font.GothamBold
			traitLabel.TextXAlignment = Enum.TextXAlignment.Left
			traitLabel.TextTruncate = Enum.TextTruncate.AtEnd
			traitLabel.Parent = traitRow

			mc.mobileButton({
				parent = traitRow,
				text = "ADD",
				size = UDim2.new(0, 72, 0, 44),
				position = UDim2.new(1, -150, 0, 2),
				color = theme.Green,
				textColor = theme.Bg,
				textSize = 13,
				callback = function()
					devToolsAction:FireServer("add_trait", { TraitId = trait.Id })
				end,
			})

			mc.mobileButton({
				parent = traitRow,
				text = "REM",
				size = UDim2.new(0, 72, 0, 44),
				position = UDim2.new(1, -72, 0, 2),
				color = theme.Bad,
				textSize = 13,
				callback = function()
					devToolsAction:FireServer("remove_trait", { TraitId = trait.Id })
				end,
			})
		end
	end
end

local function openPanel()
	gui.Enabled = true
	sheet.Visible = true
end

local function closePanel()
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	if game.PlaceId ~= TESTING_PLACE_ID then return end

	local getDevTools = ReplicatedStorage:WaitForChild("GetDevTools")
	local devToolsAction = ReplicatedStorage:WaitForChild("DevToolsAction")

	local ok, payload = pcall(function() return getDevTools:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" or payload.Allowed ~= true then return end

	gui = Instance.new("ScreenGui")
	gui.Name = "MobileDevToolsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 643
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileDevToolsSheet",
		parent = gui,
		title = "DEV TOOLS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildOfClass("ScrollingFrame")

	buildContent(payload, devToolsAction)

	uiState.subscribe(function(route)
		if route == "dev" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
