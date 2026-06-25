local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local corner = mc.corner
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getJobs = ReplicatedStorage:WaitForChild("GetJobs")
local jobAction = ReplicatedStorage:WaitForChild("JobAction")
local TEST_PURCHASE_PLACE_ID = 104206065947170

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local subtitleLabel: TextLabel

local isOpen = false
local busy = false
local refresh: () -> ()

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function buildRouteCard(payload: { [string]: any }, order: number)
	local isRogue = payload.IsRogueSorcerer == true
	local canGo = payload.CanGoRogue == true
	local rogueProductId = tonumber(payload.GoRogueProductId) or 0
	local roguePassId = tonumber(payload.GoRoguePassId) or 0
	local canPurchaseRogue = canGo and (roguePassId > 0 or rogueProductId > 0)
	local rogueUsed = (tonumber(payload.RogueActionsThisYear) or 0) >= 1

	local card = mobileCard({
		parent = scroll,
		accentColor = theme.Purple,
		order = order,
	})

	mobileLabel({
		parent = card,
		text = isRogue and "Rogue Sorcerer Route" or "Route Choice",
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = card,
		text = isRogue and "You are outside official Jujutsu society."
			or "Cut ties with Jujutsu High and move independently.",
		size = 13,
		color = theme.SubText,
		order = 2,
	})

	local btnLabel = isRogue and "ROGUE"
		or (canPurchaseRogue and "GO ROGUE" or (canGo and "SET ID" or "LOCKED"))
	local btnColor = canPurchaseRogue and Color3.fromRGB(78, 46, 105) or theme.Button

	mobileButton({
		parent = card,
		text = btnLabel,
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.new(0, 0, 0, 0),
		color = btnColor,
		textColor = (canPurchaseRogue or isRogue) and theme.Text or theme.SubText,
		textSize = 14,
		order = 3,
		callback = function()
			if not canPurchaseRogue or busy then
				return
			end
			busy = true
			if game.PlaceId == TEST_PURCHASE_PLACE_ID then
				jobAction:FireServer("go_rogue", "test_place_bypass")
			else
				if roguePassId > 0 then
					MarketplaceService:PromptGamePassPurchase(player, roguePassId)
				else
					MarketplaceService:PromptProductPurchase(player, rogueProductId)
				end
			end
			task.delay(0.8, function()
				busy = false
				if isOpen then
					refresh()
				end
			end)
		end,
	})

	if isRogue then
		local actions = {
			{ Id = "rogue_black_market", Text = "MARKET" },
			{ Id = "rogue_hide_trail", Text = "HIDE" },
			{ Id = "rogue_contract", Text = "CONTRACT" },
		}
		for i, action in ipairs(actions) do
			mobileButton({
				parent = card,
				text = rogueUsed and "USED" or action.Text,
				size = UDim2.new(1, 0, 0, 46),
				position = UDim2.new(0, 0, 0, 0),
				color = rogueUsed and theme.Button or Color3.fromRGB(64, 42, 82),
				textColor = rogueUsed and theme.SubText or theme.Text,
				textSize = 14,
				order = 3 + i,
				callback = function()
					if rogueUsed or busy then
						return
					end
					busy = true
					jobAction:FireServer(action.Id, "")
					task.delay(0.8, function()
						busy = false
						if isOpen then
							refresh()
						end
					end)
				end,
			})
		end
	end
end

local function buildJobCard(job: { [string]: any }, canApply: boolean, playerAge: number, order: number)
	local tooYoung = playerAge < (tonumber(job.MinAge) or 0)
	local eligible = canApply and not tooYoung

	local card = mobileCard({
		parent = scroll,
		order = order,
	})

	mobileLabel({
		parent = card,
		text = tostring(job.Title or "Job"),
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mobileLabel({
		parent = card,
		text = "$" .. tostring(job.Pay or 0) .. " / year  ·  " .. tostring(job.Acceptance or 0) .. "% acceptance",
		size = 14,
		color = theme.Gold,
		font = Enum.Font.GothamBold,
		order = 2,
	})

	mobileLabel({
		parent = card,
		text = "Best with " .. tostring(job.Stat or "stats") .. "  ·  Age " .. tostring(job.MinAge or 0) .. "+",
		size = 13,
		color = theme.SubText,
		order = 3,
	})

	local btnLabel: string
	if not canApply then
		btnLabel = "USED"
	elseif tooYoung then
		btnLabel = "AGE " .. tostring(job.MinAge) .. "+"
	else
		btnLabel = "APPLY"
	end

	local btnColor: Color3
	if eligible then
		btnColor = Color3.fromRGB(38, 82, 54)
	elseif tooYoung then
		btnColor = Color3.fromRGB(58, 48, 38)
	else
		btnColor = theme.Button
	end

	mobileButton({
		parent = card,
		text = btnLabel,
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.new(0, 0, 0, 0),
		color = btnColor,
		textColor = eligible and theme.Text or theme.SubText,
		textSize = 15,
		order = 4,
		callback = function()
			if not eligible or busy then
				return
			end
			busy = true
			jobAction:FireServer("apply", job.Id)
			task.delay(0.8, function()
				busy = false
				if isOpen then
					refresh()
				end
			end)
		end,
	})
end

function refresh()
	clearScroll()
	local ok, payload = pcall(function()
		return getJobs:InvokeServer()
	end)
	if not ok or typeof(payload) ~= "table" then
		subtitleLabel.Text = "Civilian route jobs are unavailable."
		return
	end

	local playerAge = tonumber(payload.Age) or 0
	local jobLevel = tonumber(payload.JobLevel) or 0
	local salary = tonumber(payload.JobSalary) or 0
	local careerText = jobLevel > 0 and (" · Lv " .. tostring(jobLevel) .. " · $" .. tostring(salary) .. "/yr") or ""
	subtitleLabel.Text = "Age "
		.. tostring(playerAge)
		.. " · "
		.. tostring(payload.CurrentJob or "Unemployed")
		.. careerText
		.. " · Year "
		.. tostring(payload.Year or "?")
		.. " · Apps "
		.. tostring(payload.ApplicationsThisYear or 0)
		.. "/1"

	local hasAgeLocked = false
	for _, job in ipairs(payload.Jobs or {}) do
		if playerAge < (tonumber(job.MinAge) or 0) then
			hasAgeLocked = true
			break
		end
	end

	local order = 0
	if hasAgeLocked then
		local note = mobileCard({
			parent = scroll,
			color = Color3.fromRGB(40, 32, 20),
			accentColor = theme.Gold,
			order = order,
		})
		mobileLabel({
			parent = note,
			text = "Some roles need you to be older — locked jobs show their minimum age.",
			size = 13,
			color = theme.Gold,
			order = 1,
		})
		order += 1
	end

	buildRouteCard(payload, order)
	order += 1

	for _, job in ipairs(payload.Jobs or {}) do
		buildJobCard(job, payload.CanApply == true, playerAge, order)
		order += 1
	end
end

local function openPanel()
	isOpen = true
	gui.Enabled = true
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileJobsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 620
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileJobsSheet",
		parent = gui,
		title = "JOBS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, -20, 0, 34)
	subtitleLabel.Position = UDim2.new(0, 10, 0, 50)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.TextSize = 13
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextColor3 = theme.SubText
	subtitleLabel.TextWrapped = true
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.Text = ""
	subtitleLabel.Parent = sheet

	scroll.Position = UDim2.new(0, 0, 0, 86)
	scroll.Size = UDim2.new(1, 0, 1, -86)

	sheet.Visible = true

	jobAction.OnClientEvent:Connect(function()
		if isOpen then
			refresh()
		end
	end)

	uiState.subscribe(function(route)
		if route == "jobs" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
