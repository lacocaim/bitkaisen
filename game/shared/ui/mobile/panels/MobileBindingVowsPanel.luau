local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
local getBindingVows = ReplicatedStorage:WaitForChild("GetBindingVows")
local bindingVowAction = ReplicatedStorage:WaitForChild("BindingVowAction")

local PREVIEW_RULES = {
	SeverityPower = {
		minor = 1,
		serious = 2,
		deathly = 3,
	},

	SacrificeCost = {
		body = function(power)
			return "-" .. tostring(8 * power) .. " Health now"
		end,
		joy = function(power)
			return "-" .. tostring(10 * power) .. " Happiness now"
		end,
		wealth = function(power)
			return "Lose " .. tostring(15 * power) .. "% of current money"
		end,
		name = function(power)
			return "-" .. tostring(7 * power) .. " Reputation now"
		end,
		control = function(power)
			return "-" .. tostring(4 * power) .. " Technique Mastery now"
		end,
		reserves = function(power)
			return "-" .. tostring(18 * power) .. " Cursed Energy now"
		end,
	},

	RewardGain = {
		cursed_energy = function(power)
			return "+" .. tostring(28 * power) .. " Cursed Energy now"
		end,
		mastery = function(power)
			return "+" .. tostring(7 * power) .. " Technique Mastery now"
		end,
		recognition = function(power)
			return "+" .. tostring(10 * power) .. " Reputation now"
		end,
		recommendations = function(power)
			return "+" .. tostring(power) .. " Teacher Recommendations now"
		end,
		clan = function(power)
			return "+" .. tostring(8 * power) .. " Clan Reputation now"
		end,
	},

	SacrificeBreak = {
		body = function(power)
			return "-" .. tostring(8 * power) .. " Health backlash"
		end,
		joy = function(power)
			return "-" .. tostring(8 * power) .. " Happiness backlash"
		end,
		wealth = function(power)
			return "lose " .. tostring(10 * power) .. "% of current money as backlash"
		end,
		name = function(power)
			return "-" .. tostring(10 * power) .. " Reputation backlash"
		end,
		control = function(power)
			return "-" .. tostring(5 * power) .. " Technique Mastery backlash"
		end,
		reserves = function(power)
			return "-" .. tostring(15 * power) .. " Cursed Energy backlash"
		end,
	},

	RewardBreak = {
		cursed_energy = function(power)
			return "-" .. tostring(18 * power) .. " Cursed Energy"
		end,
		mastery = function(power)
			return "-" .. tostring(5 * power) .. " Technique Mastery"
		end,
		recognition = function(power)
			return "-" .. tostring(8 * power) .. " Reputation"
		end,
		recommendations = function(power)
			return "-" .. tostring(power) .. " Teacher Recommendations"
		end,
		clan = function(power)
			return "-" .. tostring(7 * power) .. " Clan Reputation"
		end,
	},
}

local MATCHING_REWARD_BY_SACRIFICE = {
	control = "mastery",
	name = "recognition",
	reserves = "cursed_energy",
}

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local currentStats: any = nil
local currentPayload: any = nil
local currentTab = "Custom"
local isOpen = false
local loading = false

local pendingMakePresetId: string? = nil
local pendingBreakPresetId: string? = nil
local pendingBreakCustomId: string? = nil
local pendingSignCustom = false

local selectedSacrificeIndex = 1
local selectedRewardIndex = 1
local selectedSeverityIndex = 1

local rebuild: () -> ()

local function clearScroll()
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function safeNumber(value: any, default: number): number
	local n = tonumber(value)
	return if n then n else default
end

local function getStatLine(): string
	if typeof(currentStats) ~= "table" then
		return "No active life loaded."
	end
	local age = safeNumber(currentStats.Age, 0)
	local month = tostring(currentStats.CurrentMonthName or currentStats.CurrentMonth or "")
	local grade = tostring(currentStats.Grade or "Non-Sorcerer")
	local ce = safeNumber(currentStats.CursedEnergy, 0)
	local mastery = safeNumber(currentStats.TechniqueMastery, 0)
	if month ~= "" then
		return "Age " .. tostring(age) .. " \u{2022} " .. month .. "\n" .. grade .. " \u{2022} CE " .. tostring(ce) .. " \u{2022} Mastery " .. tostring(mastery)
	end
	return "Age " .. tostring(age) .. " \u{2022} " .. grade .. "\nCE " .. tostring(ce) .. " \u{2022} Mastery " .. tostring(mastery)
end

local function getCustomOptions()
	local payload = currentPayload or {}
	local options = typeof(payload.CustomOptions) == "table" and payload.CustomOptions or {}
	return {
		Sacrifices = typeof(options.Sacrifices) == "table" and options.Sacrifices or {},
		Rewards = typeof(options.Rewards) == "table" and options.Rewards or {},
		Severities = typeof(options.Severities) == "table" and options.Severities or {},
	}
end

local function getSelected(list: { any }, index: number): any?
	if typeof(list) ~= "table" or #list <= 0 then
		return nil
	end
	index = math.clamp(index, 1, #list)
	return list[index]
end

local function cycleIndex(list: { any }, index: number, direction: number): number
	if typeof(list) ~= "table" or #list <= 0 then
		return 1
	end
	index += direction
	if index > #list then
		index = 1
	elseif index < 1 then
		index = #list
	end
	return index
end

local function getPowerFromSeverity(severity: any): number
	local id = tostring(severity and severity.Id or "")
	return PREVIEW_RULES.SeverityPower[id] or 1
end

local function getCostText(sacrifice: any, power: number): string
	local id = tostring(sacrifice and sacrifice.Id or "")
	local builder = PREVIEW_RULES.SacrificeCost[id]
	if builder then
		return builder(power)
	end
	return "Cost depends on the selected sacrifice."
end

local function getGainText(reward: any, power: number): string
	local id = tostring(reward and reward.Id or "")
	local builder = PREVIEW_RULES.RewardGain[id]
	if builder then
		return builder(power)
	end
	return "Gain depends on the selected reward."
end

local function getPenaltyText(sacrifice: any, reward: any, power: number): string
	local sacrificeId = tostring(sacrifice and sacrifice.Id or "")
	local rewardId = tostring(reward and reward.Id or "")
	local sacrificeBuilder = PREVIEW_RULES.SacrificeBreak[sacrificeId]
	local rewardBuilder = PREVIEW_RULES.RewardBreak[rewardId]
	local sacrificeText = sacrificeBuilder and sacrificeBuilder(power) or "sacrifice backlash"
	local rewardText = rewardBuilder and rewardBuilder(power) or "reward backlash"
	return sacrificeText .. ", " .. rewardText .. ", -" .. tostring(8 * power) .. " Reputation"
end

local function resetPending()
	pendingMakePresetId = nil
	pendingBreakPresetId = nil
	pendingBreakCustomId = nil
	pendingSignCustom = false
end

local function fetchPayload()
	if loading then
		return currentPayload
	end
	loading = true

	local ok, payload = pcall(function()
		return getBindingVows:InvokeServer()
	end)

	loading = false

	if ok and typeof(payload) == "table" then
		currentPayload = payload
		return payload
	end

	warn("[MobileBindingVowsPanel] Failed to load vows:", payload)
	currentPayload = {
		ActiveVows = {},
		BrokenBindingVows = {},
		CustomVows = {},
		CustomOptions = { Sacrifices = {}, Rewards = {}, Severities = {} },
		Vows = {},
	}
	return currentPayload
end

local function makeTabBar(order: number)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 44)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.LayoutOrder = order
	bar.Parent = scroll

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 40)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 0)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = bar

	mc.mobileButton({
		parent = bar,
		text = "CUSTOM",
		size = UDim2.new(0.48, 0, 0, 40),
		color = if currentTab == "Custom" then theme.Purple else theme.Button,
		textSize = 14,
		order = 1,
		callback = function()
			currentTab = "Custom"
			resetPending()
			rebuild()
		end,
	})

	mc.mobileButton({
		parent = bar,
		text = "PRESETS",
		size = UDim2.new(0.48, 0, 0, 40),
		color = if currentTab == "Preset" then theme.Purple else theme.Button,
		textSize = 14,
		order = 2,
		callback = function()
			currentTab = "Preset"
			resetPending()
			rebuild()
		end,
	})

	return bar
end

local function makeInfoCard(order: number)
	local card = mc.mobileCard({ parent = scroll, order = order })
	mc.mobileLabel({
		parent = card,
		text = "CURRENT LIFE",
		size = 12,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})
	mc.mobileLabel({
		parent = card,
		text = getStatLine(),
		size = 12,
		color = theme.SubText,
		order = 2,
	})
end

local function makeSelectorRow(parent: Frame, sectionNum: number, title: string, valueName: string, description: string, onPrev: () -> (), onNext: () -> (), order: number)
	local card = mc.mobileCard({ parent = parent, order = order, accentColor = theme.Stroke })

	mc.mobileLabel({
		parent = card,
		text = "Section " .. tostring(sectionNum) .. ": " .. title,
		size = 12,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	local selectorFrame = Instance.new("Frame")
	selectorFrame.Size = UDim2.new(1, 0, 0, 40)
	selectorFrame.BackgroundColor3 = theme.Panel
	selectorFrame.BorderSizePixel = 0
	selectorFrame.LayoutOrder = 2
	selectorFrame.Parent = card
	mc.corner(selectorFrame, 8)

	local prevBtn = Instance.new("TextButton")
	prevBtn.Size = UDim2.fromOffset(44, 36)
	prevBtn.Position = UDim2.new(0, 2, 0.5, -18)
	prevBtn.BackgroundColor3 = theme.Button
	prevBtn.BorderSizePixel = 0
	prevBtn.Text = "<"
	prevBtn.TextColor3 = theme.Text
	prevBtn.TextSize = 16
	prevBtn.Font = Enum.Font.GothamBold
	prevBtn.AutoButtonColor = false
	prevBtn.Parent = selectorFrame
	mc.corner(prevBtn, 8)
	prevBtn.MouseButton1Click:Connect(onPrev)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -96, 1, 0)
	valueLabel.Position = UDim2.new(0, 48, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = valueName
	valueLabel.TextColor3 = theme.Text
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.Parent = selectorFrame

	local nextBtn = Instance.new("TextButton")
	nextBtn.Size = UDim2.fromOffset(44, 36)
	nextBtn.AnchorPoint = Vector2.new(1, 0)
	nextBtn.Position = UDim2.new(1, -2, 0.5, -18)
	nextBtn.BackgroundColor3 = theme.Button
	nextBtn.BorderSizePixel = 0
	nextBtn.Text = ">"
	nextBtn.TextColor3 = theme.Text
	nextBtn.TextSize = 16
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.AutoButtonColor = false
	nextBtn.Parent = selectorFrame
	mc.corner(nextBtn, 8)
	nextBtn.MouseButton1Click:Connect(onNext)

	mc.mobileLabel({
		parent = card,
		text = description,
		size = 11,
		color = theme.SubText,
		order = 3,
	})
end

local function makePreviewCard(sacrifice: any, reward: any, severity: any, power: number, invalidSameStat: boolean, order: number)
	local contractName = tostring(severity.Name or "Minor") .. " Vow of " .. tostring(reward.Name or "Power")
	local statement = "I offer " .. tostring(sacrifice.Name or "Something") .. ". In return, I claim " .. tostring(reward.Name or "Something") .. "."
	local costText = getCostText(sacrifice, power)
	local gainText = getGainText(reward, power)
	local penaltyText = getPenaltyText(sacrifice, reward, power)

	local card = mc.mobileCard({ parent = scroll, order = order, accentColor = theme.Purple })

	mc.mobileLabel({
		parent = card,
		text = "PREVIEW",
		size = 12,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = contractName,
		size = 16,
		color = theme.Purple,
		font = Enum.Font.GothamBlack,
		order = 2,
	})

	mc.mobileLabel({
		parent = card,
		text = if invalidSameStat then "This contract cancels itself out. Choose a different reward or sacrifice." else statement,
		size = 13,
		color = if invalidSameStat then theme.Bad else theme.Text,
		order = 3,
	})

	mc.mobileLabel({
		parent = card,
		text = "Cost: " .. costText,
		size = 13,
		color = theme.Bad,
		order = 4,
	})

	mc.mobileLabel({
		parent = card,
		text = "Gain: " .. gainText,
		size = 13,
		color = theme.Green,
		order = 5,
	})

	mc.mobileLabel({
		parent = card,
		text = "Req: " .. (if invalidSameStat then "Sacrifice and reward cannot be the same stat." else tostring(severity.RequirementText or "No requirement.")),
		size = 12,
		color = if invalidSameStat then theme.Bad else theme.SubText,
		order = 6,
	})

	mc.mobileLabel({
		parent = card,
		text = "Penalty if broken: " .. penaltyText,
		size = 11,
		color = theme.Bad,
		font = Enum.Font.GothamBold,
		order = 7,
	})

	if not invalidSameStat then
		mc.mobileButton({
			parent = card,
			text = if pendingSignCustom then "CONFIRM SIGNATURE" else "SIGN CONTRACT",
			size = UDim2.new(1, 0, 0, 46),
			color = if pendingSignCustom then theme.Red else theme.Purple,
			textSize = 14,
			order = 8,
			callback = function()
				if not pendingSignCustom then
					pendingSignCustom = true
					pendingMakePresetId = nil
					pendingBreakPresetId = nil
					pendingBreakCustomId = nil
					rebuild()
					return
				end
				pendingSignCustom = false
				bindingVowAction:FireServer("MakeCustomVow", {
					SacrificeId = tostring(sacrifice.Id),
					RewardId = tostring(reward.Id),
					SeverityId = tostring(severity.Id),
				})
			end,
		})
	else
		mc.mobileLabel({
			parent = card,
			text = "Cannot sign — sacrifice and reward target the same stat.",
			size = 12,
			color = theme.Bad,
			font = Enum.Font.GothamBold,
			order = 8,
		})
	end
end

local function makeCustomTab()
	local options = getCustomOptions()
	local sacrifices = options.Sacrifices
	local rewards = options.Rewards
	local severities = options.Severities

	if #sacrifices <= 0 or #rewards <= 0 or #severities <= 0 then
		local card = mc.mobileCard({ parent = scroll, order = 10 })
		mc.mobileLabel({
			parent = card,
			text = "Custom contracts need the updated GameManager payload. CustomOptions came back empty.",
			size = 13,
			color = theme.SubText,
			font = Enum.Font.GothamBold,
		})
		return
	end

	selectedSacrificeIndex = math.clamp(selectedSacrificeIndex, 1, #sacrifices)
	selectedRewardIndex = math.clamp(selectedRewardIndex, 1, #rewards)
	selectedSeverityIndex = math.clamp(selectedSeverityIndex, 1, #severities)

	local sacrifice = getSelected(sacrifices, selectedSacrificeIndex)
	local reward = getSelected(rewards, selectedRewardIndex)
	local severity = getSelected(severities, selectedSeverityIndex)

	if not sacrifice or not reward or not severity then
		local card = mc.mobileCard({ parent = scroll, order = 10 })
		mc.mobileLabel({
			parent = card,
			text = "Custom contract options loaded incorrectly.",
			size = 13,
			color = theme.Bad,
			font = Enum.Font.GothamBold,
		})
		return
	end

	local power = getPowerFromSeverity(severity)
	local invalidSameStat = MATCHING_REWARD_BY_SACRIFICE[tostring(sacrifice.Id or "")] == tostring(reward.Id or "")

	makeSelectorRow(scroll, 1, "What do you sacrifice?",
		tostring(sacrifice.Name or "Unknown"),
		tostring(sacrifice.Line or "Choose what the vow takes from you."),
		function()
			selectedSacrificeIndex = cycleIndex(sacrifices, selectedSacrificeIndex, -1)
			pendingSignCustom = false
			rebuild()
		end,
		function()
			selectedSacrificeIndex = cycleIndex(sacrifices, selectedSacrificeIndex, 1)
			pendingSignCustom = false
			rebuild()
		end,
		10
	)

	makeSelectorRow(scroll, 2, "What do you gain?",
		tostring(reward.Name or "Unknown"),
		tostring(reward.Line or "Choose what the vow gives you."),
		function()
			selectedRewardIndex = cycleIndex(rewards, selectedRewardIndex, -1)
			pendingSignCustom = false
			rebuild()
		end,
		function()
			selectedRewardIndex = cycleIndex(rewards, selectedRewardIndex, 1)
			pendingSignCustom = false
			rebuild()
		end,
		11
	)

	makeSelectorRow(scroll, 3, "How strict is the vow?",
		tostring(severity.Name or "Unknown"),
		tostring(severity.RequirementText or "No requirement listed."),
		function()
			selectedSeverityIndex = cycleIndex(severities, selectedSeverityIndex, -1)
			pendingSignCustom = false
			rebuild()
		end,
		function()
			selectedSeverityIndex = cycleIndex(severities, selectedSeverityIndex, 1)
			pendingSignCustom = false
			rebuild()
		end,
		12
	)

	makePreviewCard(sacrifice, reward, severity, power, invalidSameStat, 13)

	-- Signed custom vows list
	local customVows = typeof(currentPayload) == "table" and currentPayload.CustomVows or nil

	local sectionHeader = Instance.new("Frame")
	sectionHeader.Size = UDim2.new(1, 0, 0, 28)
	sectionHeader.BackgroundTransparency = 1
	sectionHeader.LayoutOrder = 50
	sectionHeader.Parent = scroll
	mc.mobileLabel({
		parent = sectionHeader,
		text = "SIGNED CUSTOM CONTRACTS",
		size = 14,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	if typeof(customVows) ~= "table" or #customVows <= 0 then
		local card = mc.mobileCard({ parent = scroll, order = 51 })
		mc.mobileLabel({
			parent = card,
			text = "No custom vows signed yet. Draft a contract above to create one.",
			size = 13,
			color = theme.Muted,
		})
		return
	end

	for i, vow in ipairs(customVows) do
		local owned = vow.Owned == true
		local broken = vow.Broken == true

		local accentColor = if owned then theme.Green elseif broken then theme.Bad else theme.Stroke
		local card = mc.mobileCard({ parent = scroll, order = 50 + i + 1, accentColor = accentColor })

		mc.mobileLabel({
			parent = card,
			text = tostring(vow.Name or "Binding Vow"),
			size = 15,
			color = if owned then theme.Green elseif broken then theme.Bad else theme.Text,
			font = Enum.Font.GothamBlack,
			order = 1,
		})

		mc.mobileLabel({
			parent = card,
			text = if owned then "ACTIVE" elseif broken then "BROKEN" else "SIGNED",
			size = 11,
			color = if owned then theme.Green elseif broken then theme.Bad else theme.Muted,
			font = Enum.Font.GothamBold,
			order = 2,
		})

		mc.mobileLabel({
			parent = card,
			text = tostring(vow.Description or ""),
			size = 12,
			color = theme.SubText,
			order = 3,
		})

		mc.mobileLabel({
			parent = card,
			text = "Cost: " .. tostring(vow.CostText or "Unknown"),
			size = 12,
			color = theme.Bad,
			order = 4,
		})

		mc.mobileLabel({
			parent = card,
			text = "Gain: " .. tostring(vow.BonusText or "Unknown"),
			size = 12,
			color = theme.Green,
			order = 5,
		})

		if owned then
			local isPending = pendingBreakCustomId == vow.Id
			mc.mobileButton({
				parent = card,
				text = if isPending then "CONFIRM BREAK" else "BREAK VOW",
				size = UDim2.new(1, 0, 0, 44),
				color = theme.Red,
				textSize = 14,
				order = 6,
				callback = function()
					if not isPending then
						pendingBreakCustomId = vow.Id
						pendingBreakPresetId = nil
						pendingMakePresetId = nil
						pendingSignCustom = false
						rebuild()
						return
					end
					pendingBreakCustomId = nil
					bindingVowAction:FireServer("BreakCustomVow", tostring(vow.Id))
				end,
			})

			if isPending then
				mc.mobileLabel({
					parent = card,
					text = tostring(vow.BreakCostText or "Backlash will occur."),
					size = 11,
					color = theme.Bad,
					font = Enum.Font.GothamBold,
					order = 7,
				})
			end
		elseif broken then
			mc.mobileLabel({
				parent = card,
				text = "Broken for this life.",
				size = 12,
				color = theme.Bad,
				font = Enum.Font.GothamBold,
				order = 6,
			})
		end
	end
end

local function makePresetTab()
	local vows = typeof(currentPayload) == "table" and currentPayload.Vows or nil

	local sectionHeader = Instance.new("Frame")
	sectionHeader.Size = UDim2.new(1, 0, 0, 28)
	sectionHeader.BackgroundTransparency = 1
	sectionHeader.LayoutOrder = 10
	sectionHeader.Parent = scroll
	mc.mobileLabel({
		parent = sectionHeader,
		text = "PRESET BINDING VOWS",
		size = 14,
		color = theme.Gold,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	if typeof(vows) ~= "table" or #vows <= 0 then
		local card = mc.mobileCard({ parent = scroll, order = 11 })
		mc.mobileLabel({
			parent = card,
			text = "No preset Binding Vows are available yet.",
			size = 13,
			color = theme.Muted,
		})
		return
	end

	for i, vow in ipairs(vows) do
		local owned = vow.Owned == true
		local broken = vow.Broken == true
		local canMake = vow.CanMake == true

		local accentColor = if owned then theme.Green elseif broken then theme.Bad else theme.Stroke
		local card = mc.mobileCard({ parent = scroll, order = 10 + i + 1, accentColor = accentColor })

		mc.mobileLabel({
			parent = card,
			text = tostring(vow.Name or "Binding Vow"),
			size = 15,
			color = if owned then theme.Green elseif broken then theme.Bad else theme.Text,
			font = Enum.Font.GothamBlack,
			order = 1,
		})

		local stateText = if owned then "ACTIVE" elseif broken then "BROKEN" elseif canMake then "AVAILABLE" else "LOCKED"
		local stateColor = if owned then theme.Green elseif broken then theme.Bad elseif canMake then theme.Purple else theme.Muted

		mc.mobileLabel({
			parent = card,
			text = stateText,
			size = 11,
			color = stateColor,
			font = Enum.Font.GothamBold,
			order = 2,
		})

		mc.mobileLabel({
			parent = card,
			text = tostring(vow.RequirementText or "No requirement"),
			size = 11,
			color = theme.Gold,
			font = Enum.Font.GothamBold,
			order = 3,
		})

		mc.mobileLabel({
			parent = card,
			text = tostring(vow.Description or ""),
			size = 12,
			color = theme.SubText,
			order = 4,
		})

		mc.mobileLabel({
			parent = card,
			text = "Cost: " .. tostring(vow.CostText or "Unknown"),
			size = 12,
			color = theme.Bad,
			order = 5,
		})

		mc.mobileLabel({
			parent = card,
			text = "Gain: " .. tostring(vow.BonusText or "Unknown"),
			size = 12,
			color = theme.Green,
			order = 6,
		})

		if owned then
			local isPending = pendingBreakPresetId == vow.Id
			mc.mobileButton({
				parent = card,
				text = if isPending then "CONFIRM BREAK" else "BREAK VOW",
				size = UDim2.new(1, 0, 0, 44),
				color = theme.Red,
				textSize = 14,
				order = 7,
				callback = function()
					if not isPending then
						pendingBreakPresetId = vow.Id
						pendingBreakCustomId = nil
						pendingMakePresetId = nil
						pendingSignCustom = false
						rebuild()
						return
					end
					pendingBreakPresetId = nil
					bindingVowAction:FireServer("BreakVow", tostring(vow.Id))
				end,
			})

			if isPending then
				mc.mobileLabel({
					parent = card,
					text = tostring(vow.BreakCostText or "Backlash will occur."),
					size = 11,
					color = theme.Bad,
					font = Enum.Font.GothamBold,
					order = 8,
				})
			else
				mc.mobileLabel({
					parent = card,
					text = "Active. Breaking this vow causes backlash.",
					size = 11,
					color = theme.Gold,
					font = Enum.Font.GothamBold,
					order = 8,
				})
			end
		elseif broken then
			mc.mobileLabel({
				parent = card,
				text = "Broken for this life.",
				size = 12,
				color = theme.Bad,
				font = Enum.Font.GothamBold,
				order = 7,
			})
		elseif canMake then
			local isPending = pendingMakePresetId == vow.Id
			mc.mobileButton({
				parent = card,
				text = if isPending then "CONFIRM VOW" else "MAKE VOW",
				size = UDim2.new(1, 0, 0, 44),
				color = if isPending then theme.Red else theme.Purple,
				textSize = 14,
				order = 7,
				callback = function()
					if not isPending then
						pendingMakePresetId = vow.Id
						pendingBreakPresetId = nil
						pendingBreakCustomId = nil
						pendingSignCustom = false
						rebuild()
						return
					end
					pendingMakePresetId = nil
					bindingVowAction:FireServer("MakeVow", tostring(vow.Id))
				end,
			})

			if isPending then
				mc.mobileLabel({
					parent = card,
					text = "Tap again to sign. This is permanent unless broken.",
					size = 11,
					color = theme.Gold,
					font = Enum.Font.GothamBold,
					order = 8,
				})
			end
		else
			mc.mobileLabel({
				parent = card,
				text = tostring(vow.Reason or "Requirement not met."),
				size = 12,
				color = theme.Muted,
				font = Enum.Font.GothamBold,
				order = 7,
			})
		end
	end
end

rebuild = function()
	clearScroll()

	makeTabBar(1)
	makeInfoCard(2)

	if currentTab == "Custom" then
		makeCustomTab()
	else
		makePresetTab()
	end
end

local function openPanel()
	if isOpen then
		return
	end
	isOpen = true
	resetPending()

	currentPayload = fetchPayload()
	rebuild()

	sheet.Visible = true
	gui.Enabled = true
end

local function closePanel()
	if not isOpen then
		return
	end
	isOpen = false
	resetPending()
	sheet.Visible = false
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileBindingVowsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 625
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileBindingVowsSheet",
		parent = gui,
		title = "BINDING VOWS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	bindingVowAction.OnClientEvent:Connect(function(result)
		if typeof(result) ~= "table" then
			return
		end

		resetPending()

		if typeof(result.Data) == "table" then
			currentPayload = result.Data
		else
			currentPayload = fetchPayload()
		end

		if isOpen then
			rebuild()
		end
	end)

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		currentStats = stats
	end)

	uiState.subscribe(function(route)
		if route == "binding_vows" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
