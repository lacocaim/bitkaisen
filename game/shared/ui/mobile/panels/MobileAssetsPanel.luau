local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getAssets = ReplicatedStorage:WaitForChild("GetAssets")
local assetAction = ReplicatedStorage:WaitForChild("AssetAction")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local moneyLabel: TextLabel
local statusLabel: TextLabel
local tabHolder: Frame

local isOpen = false
local busy = false
local currentTab = "Owned"
local currentData: { [string]: any }? = nil

local tabs: { [string]: TextButton } = {}
local TWEEN_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local dojoSubPage = "Overview"
local refresh: () -> ()

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function formatMoney(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then return tostring(math.floor(value)) end
	return string.format("%.2f", value)
end

local function rarityColor(rarity)
	if rarity == "Common"    then return Color3.fromRGB(180, 180, 190) end
	if rarity == "Uncommon"  then return Color3.fromRGB(120, 240, 160) end
	if rarity == "Rare"      then return Color3.fromRGB(120, 190, 255) end
	if rarity == "Epic"      then return Color3.fromRGB(190, 130, 255) end
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 90)  end
	if rarity == "SpecialGrade" or rarity == "Mythic" then return Color3.fromRGB(255, 90, 125) end
	return Color3.fromRGB(180, 180, 190)
end

local function rarityDisplayName(rarity)
	local map = {
		Common = "Grade 4", Uncommon = "Grade 3", Rare = "Grade 2",
		Epic = "Semi-Grade 1", Legendary = "Grade 1",
		Mythic = "Special Grade", SpecialGrade = "Special Grade",
	}
	return map[tostring(rarity or "Common")] or tostring(rarity or "Common")
end

local function formatPercent(value)
	return tostring(math.clamp(math.floor((tonumber(value) or 0) + 0.5), 0, 100)) .. "%"
end

local function sanitizeActionText(text)
	text = tostring(text or "")
	text = text:gsub("|", ""):gsub("<", ""):gsub(">", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function setStatus(text, color)
	if statusLabel then
		statusLabel.Text = text or ""
		statusLabel.TextColor3 = color or theme.Muted
	end
end

----------------------------------------------------------------
-- ACTION FIRER
----------------------------------------------------------------
local function fireAssetAction(actionId, assetId)
	if busy then
		setStatus("Please wait...", theme.Gold)
		return
	end
	busy = true
	setStatus("Processing...", theme.Gold)
	assetAction:FireServer(actionId, assetId)
	task.delay(0.35, function()
		busy = false
		if isOpen then
			setStatus("Updated.", theme.Green)
			task.delay(1.2, function()
				if isOpen and statusLabel and statusLabel.Text == "Updated." then
					setStatus("")
				end
			end)
		end
	end)
end

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local function setTab(name)
	currentTab = name
	for tabName, btn in pairs(tabs) do
		if tabName == name then
			btn.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
			btn.TextColor3 = theme.Text
		else
			btn.BackgroundColor3 = theme.Button
			btn.TextColor3 = theme.SubText
		end
	end
end

local function buildTabs()
	tabHolder = Instance.new("Frame")
	tabHolder.Name = "AssetTabs"
	tabHolder.Size = UDim2.new(1, -20, 0, 40)
	tabHolder.Position = UDim2.new(0, 10, 0, 50)
	tabHolder.BackgroundTransparency = 1
	tabHolder.Parent = sheet

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = tabHolder

	for i, tabName in ipairs({ "Owned", "Shop", "Dojo" }) do
		local btn = Instance.new("TextButton")
		btn.Name = tabName .. "Tab"
		btn.Size = UDim2.new(0.333, -4, 1, 0)
		btn.BackgroundColor3 = theme.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = theme.SubText
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBlack
		btn.Text = string.upper(tabName)
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		btn.Parent = tabHolder
		corner(btn, 8)
		stroke(btn, theme.Stroke)
		btn.Activated:Connect(function()
			setTab(tabName)
			dojoSubPage = "Overview"
			refresh()
		end)
		tabs[tabName] = btn
	end
end

----------------------------------------------------------------
-- CARD BUILDERS
----------------------------------------------------------------
local function addEmptyCard(text, order)
	local card = mobileCard({ parent = scroll, order = order or 0 })
	mobileLabel({ parent = card, text = text, size = 14, color = theme.SubText, order = 1 })
end

local function addSectionHeader(text, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = theme.SubText
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.upper(text)
	lbl.LayoutOrder = order or 0
	lbl.Parent = scroll
end

----------------------------------------------------------------
-- OWNED TAB
----------------------------------------------------------------
local function buildOwnedTab(data)
	local orderIndex = 0

	addSectionHeader("Owned Assets", orderIndex)
	orderIndex += 1

	local owned = data.Owned or {}
	if #owned <= 0 then
		addEmptyCard("You do not own any assets yet.", orderIndex)
		orderIndex += 1
	else
		for _, asset in ipairs(owned) do
			local color = rarityColor(asset.Rarity)
			local card = mobileCard({ parent = scroll, order = orderIndex })

			mobileLabel({
				parent = card, text = tostring(asset.Name or "Unknown Asset"),
				size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
			})
			mobileLabel({
				parent = card,
				text = tostring(asset.Rarity or "Common") .. "  •  " .. rarityDisplayName(asset.Rarity),
				size = 12, color = color, font = Enum.Font.GothamBlack, order = 2,
			})
			mobileLabel({
				parent = card, text = tostring(asset.Description or ""),
				size = 13, color = theme.SubText, order = 3,
			})
			if asset.EffectsText and asset.EffectsText ~= "" then
				mobileLabel({
					parent = card, text = tostring(asset.EffectsText),
					size = 12, color = color, font = Enum.Font.GothamBold, order = 4,
				})
			end

			if asset.Id == "grand_dojo" and not data.ClanFounded then
				mobileButton({
					parent = card, text = "OPEN DOJO", order = 5,
					size = UDim2.new(1, 0, 0, 48), color = Color3.fromRGB(150, 100, 35),
					textSize = 14,
					callback = function()
						setTab("Dojo")
						refresh()
					end,
				})
			elseif asset.CanUse and (asset.Uses == nil or asset.Uses > 0) then
				mobileButton({
					parent = card, text = "USE", order = 5,
					size = UDim2.new(1, 0, 0, 48), color = Color3.fromRGB(85, 45, 130),
					textSize = 14,
					callback = function() fireAssetAction("Use", asset.Id) end,
				})
			else
				local passiveBtn = mobileButton({
					parent = card, text = asset.CanUse and "USED" or "PASSIVE", order = 5,
					size = UDim2.new(1, 0, 0, 48), color = theme.Button,
					textColor = theme.SubText, textSize = 14,
					callback = function() end,
				})
				passiveBtn.Active = false
			end

			orderIndex += 1
		end
	end

	addSectionHeader("Cursed Tools", orderIndex)
	orderIndex += 1

	local cursedTools = data.CursedTools or {}
	if #cursedTools <= 0 then
		addEmptyCard("No cursed tools owned yet. Defeat stronger enemies to find cursed tools.", orderIndex)
		orderIndex += 1
	else
		for _, tool in ipairs(cursedTools) do
			local color = rarityColor(tool.Rarity)
			local card = mobileCard({
				parent = scroll, order = orderIndex,
				accentColor = tool.Equipped and theme.Gold or nil,
			})

			mobileLabel({
				parent = card,
				text = tostring(tool.Name or "Cursed Tool") .. (tool.Equipped and "  [EQUIPPED]" or ""),
				size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
			})
			mobileLabel({
				parent = card, text = tostring(tool.Rarity or "Common"),
				size = 12, color = color, font = Enum.Font.GothamBlack, order = 2,
			})
			mobileLabel({
				parent = card, text = tostring(tool.Description or ""),
				size = 13, color = theme.SubText, order = 3,
			})
			if tool.EffectText and tool.EffectText ~= "" then
				mobileLabel({
					parent = card, text = tostring(tool.EffectText),
					size = 12, color = color, font = Enum.Font.GothamBold, order = 4,
				})
			end
			mobileButton({
				parent = card,
				text = tool.Equipped and "UNEQUIP" or "EQUIP",
				order = 5,
				size = UDim2.new(1, 0, 0, 48),
				color = tool.Equipped and theme.Bad or theme.Purple,
				textSize = 14,
				callback = function()
					fireAssetAction(tool.Equipped and "UnequipCursedTool" or "EquipCursedTool", tool.Id)
				end,
			})
			orderIndex += 1
		end
	end

	addSectionHeader("Cursed Tool Catalog", orderIndex)
	orderIndex += 1

	local catalog = data.CursedToolCatalog or {}
	if #catalog <= 0 then
		addEmptyCard("Cursed tool catalog data is not available yet.", orderIndex)
	else
		for _, tool in ipairs(catalog) do
			local color = rarityColor(tool.Rarity)
			local card = mobileCard({
				parent = scroll, order = orderIndex,
				accentColor = tool.Owned and color or nil,
			})

			mobileLabel({
				parent = card, text = tostring(tool.Name or "Cursed Tool"),
				size = 15, color = tool.Owned and theme.Text or theme.SubText,
				font = Enum.Font.GothamBlack, order = 1,
			})
			mobileLabel({
				parent = card, text = (tool.Owned and "OWNED" or "LOCKED") .. "  •  " .. tostring(tool.Rarity or "Common"),
				size = 12, color = tool.Owned and theme.Green or theme.Muted,
				font = Enum.Font.GothamBlack, order = 2,
			})
			mobileLabel({
				parent = card,
				text = tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Tool") .. " • Drop weight " .. tostring(tool.DropWeight or "?"),
				size = 11, color = color, font = Enum.Font.GothamBold, order = 3,
			})
			mobileLabel({
				parent = card, text = tostring(tool.EffectText or tool.Description or ""),
				size = 12, color = tool.Owned and theme.Text or theme.SubText, order = 4,
			})
			orderIndex += 1
		end
	end
end

----------------------------------------------------------------
-- SHOP TAB
----------------------------------------------------------------
local function buildShopTab(data)
	local orderIndex = 0

	addSectionHeader("Shop", orderIndex)
	orderIndex += 1

	local shop = data.Shop or {}
	if #shop <= 0 then
		addEmptyCard("The shop has no available assets.", orderIndex)
		return
	end

	local playerAge = tonumber(data.Age) or 0

	local bulkCard = mobileCard({ parent = scroll, accentColor = theme.Green, order = orderIndex })
	mobileLabel({
		parent = bulkCard, text = "Bulk Asset Purchase",
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = bulkCard,
		text = "Buy up to 5 cheapest affordable unowned assets at once.",
		size = 13, color = theme.SubText, order = 2,
	})
	mobileButton({
		parent = bulkCard,
		text = playerAge < 16 and "AGE 16+" or "BULK BUY",
		size = UDim2.new(1, 0, 0, 48),
		color = playerAge < 16 and theme.Button or theme.Green,
		textColor = playerAge < 16 and theme.SubText or theme.Bg,
		textSize = 14, order = 3,
		callback = function()
			if playerAge >= 16 then
				fireAssetAction("BulkBuyAffordable", "sealed_charm")
			end
		end,
	})
	orderIndex += 1

	for _, asset in ipairs(shop) do
		local color = rarityColor(asset.Rarity)
		local card = mobileCard({ parent = scroll, order = orderIndex })

		mobileLabel({
			parent = card, text = tostring(asset.Name or "Unknown Asset"),
			size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})

		local priceLine = "$" .. tostring(asset.Price or 0) .. "  •  " .. tostring(asset.Rarity or "Common") .. " • " .. tostring(asset.Type or "Asset")
		mobileLabel({
			parent = card, text = priceLine,
			size = 12, color = color, font = Enum.Font.GothamBlack, order = 2,
		})
		mobileLabel({
			parent = card, text = tostring(asset.Description or ""),
			size = 13, color = theme.SubText, order = 3,
		})

		local buyText = playerAge < 16 and "ASK PARENT" or "BUY"
		local actionId = playerAge < 16 and "AskParent" or "Buy"
		mobileButton({
			parent = card, text = buyText, order = 4,
			size = UDim2.new(1, 0, 0, 48),
			color = Color3.fromRGB(100, 30, 30), textSize = 14,
			callback = function()
				fireAssetAction(actionId, asset.Id)
			end,
		})
		orderIndex += 1
	end
end

----------------------------------------------------------------
-- DOJO TAB
----------------------------------------------------------------
local function getDojoRankInfo(data)
	local rep = tonumber(data.ClanReputation) or 0
	if rep < 25  then return "Minor Dojo",       rep,       25  end
	if rep < 75  then return "Rising Clan",       rep - 25,  50  end
	if rep < 150 then return "Recognized House",  rep - 75,  75  end
	if rep < 300 then return "Great Clan",        rep - 150, 150 end
	return "Legendary Clan", 300, 300
end

local function buildProgressBar(parent, labelText, current, maxVal, barColor, order)
	local wrapper = Instance.new("Frame")
	wrapper.Size = UDim2.new(1, 0, 0, 48)
	wrapper.BackgroundTransparency = 1
	wrapper.LayoutOrder = order or 0
	wrapper.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = theme.SubText
	lbl.TextSize = 11
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = string.upper(labelText)
	lbl.Parent = wrapper

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 10)
	bg.Position = UDim2.new(0, 0, 0, 18)
	bg.BackgroundColor3 = Color3.fromRGB(16, 16, 23)
	bg.BorderSizePixel = 0
	bg.Parent = wrapper
	corner(bg, 999)

	local ratio = 0
	if tonumber(maxVal) and maxVal > 0 then
		ratio = math.clamp((tonumber(current) or 0) / maxVal, 0, 1)
	end
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = barColor or theme.Gold
	fill.BorderSizePixel = 0
	fill.Parent = bg
	corner(fill, 999)

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, 0, 0, 14)
	val.Position = UDim2.new(0, 0, 0, 32)
	val.BackgroundTransparency = 1
	val.TextColor3 = barColor or theme.Gold
	val.TextSize = 11
	val.Font = Enum.Font.GothamBlack
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.Text = tostring(math.floor(tonumber(current) or 0)) .. " / " .. tostring(math.floor(tonumber(maxVal) or 0))
	val.Parent = wrapper
end

local function buildStatRow(parent, stats, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order or 0
	row.Parent = parent

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = row

	for i, stat in ipairs(stats) do
		local pill = Instance.new("Frame")
		pill.Size = UDim2.new(1 / #stats, -4, 1, 0)
		pill.BackgroundColor3 = Color3.fromRGB(16, 16, 23)
		pill.BorderSizePixel = 0
		pill.LayoutOrder = i
		pill.Parent = row
		corner(pill, 8)
		stroke(pill, theme.Stroke)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 4)
		pad.Parent = pill

		local pillLayout = Instance.new("UIListLayout")
		pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pillLayout.Padding = UDim.new(0, 0)
		pillLayout.Parent = pill

		local pillLabel = Instance.new("TextLabel")
		pillLabel.Size = UDim2.new(1, -8, 0, 14)
		pillLabel.BackgroundTransparency = 1
		pillLabel.TextColor3 = theme.Muted
		pillLabel.TextSize = 9
		pillLabel.Font = Enum.Font.GothamBlack
		pillLabel.TextXAlignment = Enum.TextXAlignment.Left
		pillLabel.Text = string.upper(stat[1])
		pillLabel.LayoutOrder = 1
		pillLabel.Parent = pill

		local pillVal = Instance.new("TextLabel")
		pillVal.Size = UDim2.new(1, -8, 0, 20)
		pillVal.BackgroundTransparency = 1
		pillVal.TextColor3 = stat[3] or theme.Text
		pillVal.TextSize = 14
		pillVal.Font = Enum.Font.GothamBlack
		pillVal.TextXAlignment = Enum.TextXAlignment.Left
		pillVal.Text = tostring(stat[2])
		pillVal.LayoutOrder = 2
		pillVal.Parent = pill
	end
end

local function buildDojoOverview(data)
	local orderIndex = 0
	local rankName, rankProgress, rankNeed = getDojoRankInfo(data)

	local summaryCard = mobileCard({ parent = scroll, accentColor = theme.Gold, order = orderIndex })
	mobileLabel({
		parent = summaryCard,
		text = tostring(data.PlayerClanName or "Unnamed Clan"),
		size = 17, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = summaryCard,
		text = rankName .. "  •  Founder: " .. tostring(data.DojoFounderName or data.Name or "Unknown"),
		size = 12, color = theme.Gold, font = Enum.Font.GothamBold, order = 2,
	})
	buildProgressBar(summaryCard, "Clan Reputation", rankProgress, rankNeed, theme.Gold, 3)
	buildStatRow(summaryCard, {
		{ "Students", tostring(data.ClanStudentCount or 0) .. "/" .. tostring(data.DojoCapacity or 3), theme.Blue },
		{ "Level", tostring(data.DojoLevel or 1), theme.Purple },
		{ "Cond.", formatPercent(data.DojoCondition or 100), theme.Green },
	}, 4)
	mobileLabel({
		parent = summaryCard,
		text = "Focus: " .. tostring(data.DojoFocus or "Balanced") .. "  •  Rerolls: " .. tostring(data.RecruitRerollTokens or 0),
		size = 11, color = theme.Muted, order = 5,
	})
	orderIndex += 1

	local upgradeCost = tonumber(data.DojoUpgradeCost)
	local upgradeCard = mobileCard({ parent = scroll, order = orderIndex })
	mobileLabel({
		parent = upgradeCard, text = "Upgrade Grand Dojo",
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = upgradeCard,
		text = upgradeCost and ("$" .. tostring(upgradeCost) .. " to raise dojo level, condition, prestige, and student capacity.") or "Already at maximum level.",
		size = 13, color = theme.SubText, order = 2,
	})
	mobileButton({
		parent = upgradeCard,
		text = upgradeCost and "UPGRADE" or "MAX",
		size = UDim2.new(1, 0, 0, 48),
		color = upgradeCost and theme.Gold or theme.Button,
		textColor = upgradeCost and theme.Bg or theme.SubText,
		textSize = 14, order = 3,
		callback = function()
			if upgradeCost then fireAssetAction("UpgradeDojo", "grand_dojo") end
		end,
	})
	orderIndex += 1

	addSectionHeader("Dojo Actions", orderIndex)
	orderIndex += 1

	local actions = {
		{ "Students",  "View and manage your clan students.",                theme.Blue },
		{ "Recruit",   "Recruit new students from the candidate board.",    theme.Green },
		{ "Training",  "Set focus and run training sessions.",              theme.Purple },
		{ "Settings",  "View clan identity and configuration.",             theme.Gold },
	}
	for _, action in ipairs(actions) do
		local card = mobileCard({ parent = scroll, order = orderIndex })
		mobileLabel({
			parent = card, text = action[1],
			size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = card, text = action[2],
			size = 13, color = theme.SubText, order = 2,
		})
		mobileButton({
			parent = card, text = string.upper(action[1]),
			size = UDim2.new(1, 0, 0, 48), color = action[3],
			textColor = theme.Bg, textSize = 14, order = 3,
			callback = function()
				dojoSubPage = action[1]
				refresh()
			end,
		})
		orderIndex += 1
	end
end

local function buildDojoStudents(data)
	local orderIndex = 0

	mobileButton({
		parent = scroll, text = "← BACK TO DOJO",
		size = UDim2.new(1, -20, 0, 44),
		position = UDim2.new(0, 10, 0, 0),
		color = theme.Button, textSize = 14, order = orderIndex,
		callback = function() dojoSubPage = "Overview"; refresh() end,
	})
	orderIndex += 1

	addSectionHeader("Students", orderIndex)
	orderIndex += 1

	local students = data.DojoStudents or {}
	if #students <= 0 then
		local card = mobileCard({ parent = scroll, order = orderIndex })
		mobileLabel({
			parent = card, text = "No students yet.",
			size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = card, text = "Recruit students from the recruit board first.",
			size = 13, color = theme.SubText, order = 2,
		})
		mobileButton({
			parent = card, text = "RECRUIT",
			size = UDim2.new(1, 0, 0, 48), color = theme.Green,
			textColor = theme.Bg, textSize = 14, order = 3,
			callback = function() dojoSubPage = "Recruit"; refresh() end,
		})
	else
		for _, student in ipairs(students) do
			local card = mobileCard({ parent = scroll, order = orderIndex })
			mobileLabel({
				parent = card,
				text = tostring(student.Name or "Unknown"),
				size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
			})
			mobileLabel({
				parent = card,
				text = tostring(student.Grade or "Non-Sorcerer") .. "  •  Age " .. tostring(student.Age or 0) .. "  •  " .. tostring(student.Gender or ""),
				size = 12, color = theme.Gold, font = Enum.Font.GothamBold, order = 2,
			})
			mobileLabel({
				parent = card,
				text = "CE: " .. tostring(student.CursedEnergy or 0) .. "  •  Technique: " .. tostring(student.CursedTechnique or "None") .. "  •  Potential: " .. tostring(student.DojoPotential or "Unknown"),
				size = 12, color = theme.SubText, order = 3,
			})
			if student.Bond ~= nil then
				mobileLabel({
					parent = card,
					text = "Bond " .. tostring(student.Bond or 0) .. "  •  Trust " .. tostring(student.Trust or 0) .. "  •  Respect " .. tostring(student.Respect or 0),
					size = 11, color = theme.Muted, order = 4,
				})
			end
			orderIndex += 1
		end
	end
end

local function buildDojoRecruit(data)
	local orderIndex = 0

	mobileButton({
		parent = scroll, text = "← BACK TO DOJO",
		size = UDim2.new(1, -20, 0, 44),
		position = UDim2.new(0, 10, 0, 0),
		color = theme.Button, textSize = 14, order = orderIndex,
		callback = function() dojoSubPage = "Overview"; refresh() end,
	})
	orderIndex += 1

	addSectionHeader("Recruit Students", orderIndex)
	orderIndex += 1

	local used  = tonumber(data.DojoStarterRecruitsUsed) or 0
	local limit = tonumber(data.DojoStarterRecruitLimit) or 3
	local candidates = data.DojoRecruitPool or {}

	local introCard = mobileCard({ parent = scroll, order = orderIndex })
	mobileLabel({
		parent = introCard,
		text = "Choose " .. tostring(limit) .. " out of 10 candidates",
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = introCard,
		text = "Slots used: " .. tostring(used) .. " / " .. tostring(limit),
		size = 13, color = theme.Gold, font = Enum.Font.GothamBold, order = 2,
	})
	orderIndex += 1

	if used >= limit then
		local doneCard = mobileCard({ parent = scroll, accentColor = theme.Gold, order = orderIndex })
		mobileLabel({
			parent = doneCard, text = "Starting recruitment complete.",
			size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = doneCard, text = "All starter slots used. Future upgrades can unlock more.",
			size = 13, color = theme.SubText, order = 2,
		})
		return
	end

	if #candidates <= 0 then
		local genCard = mobileCard({ parent = scroll, order = orderIndex })
		mobileLabel({
			parent = genCard, text = "No recruit list yet.",
			size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = genCard, text = "Generate 10 possible students for your Grand Dojo.",
			size = 13, color = theme.SubText, order = 2,
		})
		mobileButton({
			parent = genCard, text = "GENERATE",
			size = UDim2.new(1, 0, 0, 48), color = theme.Gold,
			textColor = theme.Bg, textSize = 14, order = 3,
			callback = function() fireAssetAction("GenerateRecruitPool", "grand_dojo") end,
		})
		return
	end

	for i, candidate in ipairs(candidates) do
		local card = mobileCard({ parent = scroll, order = orderIndex })
		mobileLabel({
			parent = card,
			text = tostring(candidate.Name or "Unknown"),
			size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = card,
			text = tostring(candidate.Grade or "Non-Sorcerer") .. "  •  Age " .. tostring(candidate.Age or 0) .. "  •  " .. tostring(candidate.Gender or ""),
			size = 12, color = theme.Gold, font = Enum.Font.GothamBold, order = 2,
		})
		mobileLabel({
			parent = card,
			text = "CE: " .. tostring(candidate.CursedEnergy or 0) .. "  •  Technique: " .. tostring(candidate.CursedTechnique or "None") .. "  •  Potential: " .. tostring(candidate.DojoPotential or "Unknown"),
			size = 12, color = theme.SubText, order = 3,
		})
		if candidate.Background then
			mobileLabel({
				parent = card, text = tostring(candidate.Background),
				size = 11, color = theme.Muted, order = 4,
			})
		end
		mobileButton({
			parent = card, text = "RECRUIT",
			size = UDim2.new(1, 0, 0, 48), color = theme.Green,
			textColor = theme.Bg, textSize = 14, order = 5,
			callback = function()
				fireAssetAction("RecruitCandidate", tostring(candidate.Id or i))
			end,
		})
		orderIndex += 1
	end
end

local function buildDojoTraining(data)
	local orderIndex = 0

	mobileButton({
		parent = scroll, text = "← BACK TO DOJO",
		size = UDim2.new(1, -20, 0, 44),
		position = UDim2.new(0, 10, 0, 0),
		color = theme.Button, textSize = 14, order = orderIndex,
		callback = function() dojoSubPage = "Overview"; refresh() end,
	})
	orderIndex += 1

	addSectionHeader("Training Focus", orderIndex)
	orderIndex += 1

	local focusOptions = {
		{ "Balanced",   "Even growth across bond, trust, respect, and cursed energy.", theme.Button },
		{ "Combat",     "More cursed energy and grade growth, with harder sessions.",  theme.Bad },
		{ "Discipline", "More respect and trust through strict structure.",            theme.Gold },
		{ "Theory",     "Better cursed energy control and technique growth.",          theme.Purple },
		{ "Loyalty",    "More bond, trust, and clan reputation.",                      theme.Green },
	}

	for _, opt in ipairs(focusOptions) do
		local selected = tostring(data.DojoFocus or "Balanced") == opt[1]
		local card = mobileCard({
			parent = scroll, order = orderIndex,
			accentColor = selected and theme.Gold or nil,
		})
		mobileLabel({
			parent = card, text = opt[1],
			size = 15, color = selected and theme.Gold or theme.Text,
			font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = card, text = opt[2],
			size = 13, color = theme.SubText, order = 2,
		})
		mobileButton({
			parent = card,
			text = selected and "ACTIVE" or "SELECT",
			size = UDim2.new(1, 0, 0, 48),
			color = selected and theme.Gold or opt[3],
			textColor = selected and theme.Bg or theme.Text,
			textSize = 14, order = 3,
			callback = function()
				if not selected then
					fireAssetAction("SetFocus_" .. opt[1], "grand_dojo")
				end
			end,
		})
		orderIndex += 1
	end

	addSectionHeader("Run Training", orderIndex)
	orderIndex += 1

	local trainCard = mobileCard({ parent = scroll, order = orderIndex })
	mobileLabel({
		parent = trainCard, text = "Run Training Session",
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = trainCard,
		text = "Student growth, clan reputation, possible CE/mastery gains. Cost: dojo condition and time.",
		size = 13, color = theme.SubText, order = 2,
	})
	mobileButton({
		parent = trainCard, text = "TRAIN",
		size = UDim2.new(1, 0, 0, 48), color = theme.Purple,
		textSize = 14, order = 3,
		callback = function() fireAssetAction("TrainStudents", "grand_dojo") end,
	})
end

local function buildDojoSettings(data)
	local orderIndex = 0

	mobileButton({
		parent = scroll, text = "← BACK TO DOJO",
		size = UDim2.new(1, -20, 0, 44),
		position = UDim2.new(0, 10, 0, 0),
		color = theme.Button, textSize = 14, order = orderIndex,
		callback = function() dojoSubPage = "Overview"; refresh() end,
	})
	orderIndex += 1

	addSectionHeader("Clan Settings", orderIndex)
	orderIndex += 1

	local card = mobileCard({ parent = scroll, order = orderIndex })
	mobileLabel({
		parent = card, text = "Clan Identity",
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card,
		text = "<b>Clan:</b> " .. tostring(data.PlayerClanName or "Unknown")
			.. "\n<b>Founder:</b> " .. tostring(data.DojoFounderName or "Unknown")
			.. "\n<b>Family Name:</b> " .. tostring(data.FamilyName or "Unknown")
			.. "\n<b>Focus:</b> " .. tostring(data.DojoFocus or "Balanced"),
		size = 13, color = theme.SubText, order = 2,
	})
end

local function buildDojoNoGrandDojo(data)
	local orderIndex = 0

	local card = mobileCard({ parent = scroll, accentColor = theme.Gold, order = orderIndex })
	mobileLabel({
		parent = card, text = "No Grand Dojo Owned",
		size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card,
		text = "Buy the Grand Dojo from the shop for $25,000 to found a clan, recruit students, and build your sorcerer school.",
		size = 13, color = theme.SubText, order = 2,
	})
	mobileButton({
		parent = card, text = "GO SHOP",
		size = UDim2.new(1, 0, 0, 48), color = theme.Gold,
		textColor = theme.Bg, textSize = 14, order = 3,
		callback = function() setTab("Shop"); refresh() end,
	})
	orderIndex += 1

	local joinedName = tostring(data.JoinedDojoName or "")
	if joinedName ~= "" then
		local joinedCard = mobileCard({ parent = scroll, accentColor = theme.Gold, order = orderIndex })
		mobileLabel({
			parent = joinedCard, text = "Joined Dojo",
			size = 15, color = theme.Gold, font = Enum.Font.GothamBlack, order = 1,
		})
		mobileLabel({
			parent = joinedCard, text = "You are a student at: " .. joinedName,
			size = 13, color = theme.Text, order = 2,
		})
	end
end

local function buildDojoClanNameSetup(data)
	local card = mobileCard({ parent = scroll, accentColor = theme.Gold, order = 0 })
	mobileLabel({
		parent = card, text = "Clan Name Setup",
		size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card,
		text = "Current: " .. tostring(data.FamilyName or "Unnamed") .. " Clan",
		size = 13, color = theme.Gold, font = Enum.Font.GothamBold, order = 2,
	})

	local tb = Instance.new("TextBox")
	tb.Size = UDim2.new(1, 0, 0, 48)
	tb.BackgroundColor3 = Color3.fromRGB(16, 16, 23)
	tb.BorderSizePixel = 0
	tb.TextColor3 = theme.Text
	tb.PlaceholderColor3 = theme.Muted
	tb.TextSize = 15
	tb.Font = Enum.Font.GothamBlack
	tb.TextXAlignment = Enum.TextXAlignment.Left
	tb.ClearTextOnFocus = false
	tb.Text = tostring(data.FamilyName or "Unnamed") .. " Clan"
	tb.LayoutOrder = 3
	tb.Parent = card
	corner(tb, 10)
	stroke(tb, theme.Stroke)
	local tbPad = Instance.new("UIPadding")
	tbPad.PaddingLeft = UDim.new(0, 12)
	tbPad.PaddingRight = UDim.new(0, 12)
	tbPad.Parent = tb

	mobileLabel({
		parent = card,
		text = "Confirm the clan name. The game will ask if you want your last name to match.",
		size = 12, color = theme.SubText, order = 4,
	})
	mobileButton({
		parent = card, text = "CONFIRM CLAN",
		size = UDim2.new(1, 0, 0, 48), color = theme.Gold,
		textColor = theme.Bg, textSize = 14, order = 5,
		callback = function()
			local clanName = sanitizeActionText(tb.Text)
			if clanName == "" then
				clanName = tostring(data.FamilyName or "Unnamed") .. " Clan"
			end
			fireAssetAction("ConfirmClanName|" .. clanName, "grand_dojo")
			dojoSubPage = "Recruit"
		end,
	})
end

local function buildDojoLastNameChoice(data)
	local card = mobileCard({ parent = scroll, accentColor = theme.Gold, order = 0 })
	mobileLabel({
		parent = card, text = "Change Last Name?",
		size = 16, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card,
		text = "Your clan is <b>" .. tostring(data.PlayerClanName or "Unnamed Clan") .. "</b>. Match your family name?",
		size = 13, color = theme.SubText, order = 2,
	})
	mobileButton({
		parent = card, text = "YES, CHANGE IT",
		size = UDim2.new(1, 0, 0, 48), color = theme.Green,
		textColor = theme.Bg, textSize = 14, order = 3,
		callback = function() fireAssetAction("ChangePlayerLastName", "grand_dojo") end,
	})
	mobileButton({
		parent = card, text = "NO, KEEP MINE",
		size = UDim2.new(1, 0, 0, 48), color = theme.Bad,
		textSize = 14, order = 4,
		callback = function() fireAssetAction("KeepPlayerLastName", "grand_dojo") end,
	})
end

local function buildDojoTab(data)
	if not data.HasGrandDojo then
		buildDojoNoGrandDojo(data)
		return
	end

	if not data.ClanFounded then
		buildDojoClanNameSetup(data)
		return
	end

	if data.DojoPendingLastNameChoice then
		buildDojoLastNameChoice(data)
		return
	end

	if dojoSubPage == "Students"  then buildDojoStudents(data);  return end
	if dojoSubPage == "Recruit"   then buildDojoRecruit(data);   return end
	if dojoSubPage == "Training"  then buildDojoTraining(data);  return end
	if dojoSubPage == "Settings"  then buildDojoSettings(data);  return end

	buildDojoOverview(data)
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refresh = function()
	local ok, data = pcall(function() return getAssets:InvokeServer() end)
	clearScroll()

	if not ok then
		warn("[MobileAssetsPanel] Failed to load assets:", data)
		addEmptyCard("Could not load assets. Try again later.", 0)
		return
	end

	currentData = data or {}

	if moneyLabel then
		moneyLabel.Text = "Money: $" .. formatMoney(currentData.Money or 0)
	end

	local playerAge = tonumber(currentData.Age) or 0
	if playerAge < 16 and currentData.ParentAssetRequestLimit then
		local reqLeft = math.max(0, (tonumber(currentData.ParentAssetRequestLimit) or 0) - (tonumber(currentData.ParentAssetRequestsUsed) or 0))
		local giftLeft = math.max(0, (tonumber(currentData.ParentAssetGiftLimit) or 0) - (tonumber(currentData.ParentAssetGiftsReceived) or 0))
		setStatus("Parent asks: " .. tostring(reqLeft) .. " | Gifts: " .. tostring(giftLeft), theme.Gold)
	elseif statusLabel and statusLabel.Text ~= "Processing..." then
		setStatus("")
	end

	if currentTab == "Owned" then
		buildOwnedTab(currentData)
	elseif currentTab == "Shop" then
		buildShopTab(currentData)
	elseif currentTab == "Dojo" then
		buildDojoTab(currentData)
	end
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openPanel()
	if isOpen then return end
	isOpen = true
	setTab(currentTab)
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileAssetsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 622
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileAssetsSheet",
		parent = gui,
		title = "ASSETS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	moneyLabel = Instance.new("TextLabel")
	moneyLabel.Size = UDim2.new(0.55, 0, 0, 20)
	moneyLabel.Position = UDim2.new(0, 10, 0, 50)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.TextColor3 = theme.Green
	moneyLabel.TextSize = 13
	moneyLabel.Font = Enum.Font.GothamBlack
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "Money: $0"
	moneyLabel.Parent = sheet

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.45, -10, 0, 20)
	statusLabel.Position = UDim2.new(0.55, 0, 0, 50)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = theme.Muted
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.TextWrapped = true
	statusLabel.Text = ""
	statusLabel.Parent = sheet

	buildTabs()

	scroll.Position = UDim2.new(0, 0, 0, 96)
	scroll.Size = UDim2.new(1, 0, 1, -96)

	sheet.Visible = true

	assetAction.OnClientEvent:Connect(function()
		if isOpen then refresh() end
	end)

	uiState.subscribe(function(route)
		if route == "assets" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
