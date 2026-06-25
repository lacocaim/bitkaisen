local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local playerState = require("@ui-state/playerState")
local mc = require("@ui/mobile/mobileComponents")

local theme = mc.theme
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local getMissionBoard = ReplicatedStorage:WaitForChild("GetMissionBoard")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame

local function getMissionEmptyMessage(): string
	local stats = playerState.stats()
	if not stats then return "No missions available.\nLoading your sorcerer profile..." end

	local age = tonumber(stats.Age) or 0
	local grade = tostring(stats.Grade or "Non-Sorcerer")
	local technique = tostring(stats.CursedTechnique or "None")
	local innateTechnique = tostring(stats.InnateTechnique or "None")
	local hasTechnique = technique ~= "None" or innateTechnique ~= "None"
		or stats.TechniqueKnown == true or stats.TechniqueAwakened == true
		or stats.TechniqueUsable == true
	local isUnregistered = string.sub(grade, 1, 13) == "Unregistered "
	local isOfficialSorcerer = (stats.InJujutsuHigh == true or stats.RegisteredSorcerer == true)
		and not isUnregistered

	if age < 16 then return "No official missions available.\nYou need to be at least 16." end
	if not hasTechnique then return "No missions available.\nAwaken a cursed technique first." end
	if not isOfficialSorcerer then
		if isUnregistered then
			return "No official missions available.\nApply to Jujutsu High to register your " .. grade .. "."
		end
		return "No official missions available.\nApply to Jujutsu High and become a registered sorcerer first."
	end
	if stats.TechniqueUsable == false then
		return "No missions available.\nYour technique exists, but it is not usable in missions yet."
	end
	return "No missions available.\nCheck your official grade or try again later."
end

local function clearList()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function createMessageCard(text: string, color: Color3?)
	local card = mc.mobileCard({ parent = scroll, order = 1 })
	mc.mobileLabel({
		parent = card,
		text = text,
		size = 14,
		color = color or theme.SubText,
		font = Enum.Font.GothamBold,
	})
end

local function createMissionCard(missionData, order: number)
	local riskColor = missionData.RiskColor or theme.Muted

	local card = mc.mobileCard({
		parent = scroll,
		accentColor = riskColor,
		order = order,
	})

	mc.mobileLabel({
		parent = card,
		text = tostring(missionData.Title or "Unknown Mission"),
		size = 15,
		color = theme.Text,
		font = Enum.Font.GothamBlack,
		order = 1,
	})

	mc.mobileLabel({
		parent = card,
		text = "RISK \u{2022} " .. tostring(missionData.Grade or "Unknown"),
		size = 13,
		color = riskColor,
		font = Enum.Font.GothamBlack,
		order = 2,
	})

	local rewardText = missionData.RewardText
	if not rewardText or rewardText == "" then
		local rewardRep = tonumber(missionData.RewardRep) or 0
		local repText = "Rep +" .. tostring(rewardRep)
		if rewardRep < 0 then repText = "Rep " .. tostring(rewardRep) end
		rewardText = "CE +" .. tostring(missionData.RewardCE or 0)
			.. " \u{2022} $" .. tostring(missionData.RewardMoney or 0)
			.. " \u{2022} " .. repText
	end

	mc.mobileLabel({
		parent = card,
		text = rewardText,
		size = 13,
		color = theme.SubText,
		order = 3,
	})

	mc.mobileButton({
		parent = card,
		text = "ACCEPT MISSION",
		size = UDim2.new(1, 0, 0, 46),
		color = theme.Red,
		textColor = theme.Text,
		textSize = 14,
		order = 4,
		callback = function()
			if not missionData.Id then return end
			updateLifeEvent:FireServer("DoMission", missionData.Id)
			uiState.closeRoute()
		end,
	})
end

local function refresh()
	clearList()

	local ok, board = pcall(function()
		return getMissionBoard:InvokeServer()
	end)

	if not ok then
		createMessageCard("Could not load missions.\nCheck server output.", theme.Bad)
		return
	end

	if not board or #board <= 0 then
		createMessageCard(getMissionEmptyMessage(), theme.SubText)
		return
	end

	for i, missionData in ipairs(board) do
		createMissionCard(missionData, i)
	end
end

local function openPanel()
	gui.Enabled = true
	refresh()
end

local function closePanel()
	gui.Enabled = false
end

local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenMobileMissionsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 620
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mc.mobileSheet({
		name = "MobileMissionsSheet",
		parent = gui,
		title = "MISSIONS",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	uiState.subscribe(function(route)
		if route == "missions" then
			sheet.Visible = true
			openPanel()
		else
			sheet.Visible = false
			closePanel()
		end
	end)
end

return { init = init }
