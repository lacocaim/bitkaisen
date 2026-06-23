-- LocalScript: BitKaisenEventPopupDeduper
-- Location: StarterPlayerScripts
-- Purpose:
--   Emergency release-safe cleanup for duplicate life event choice popups.
--   This does NOT handle game logic. It only hides extra duplicate UI roots
--   when multiple LocalScripts are listening to ShowMissionSituation.
--
-- Why this exists:
--   If two different client scripts both connect to ShowMissionSituation,
--   one server event can create two choice windows at the same time.
--   This cleaner keeps the newer/fancy BitKaisen-style event card when possible
--   and destroys the extra basic duplicate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local showMissionSituation = ReplicatedStorage:WaitForChild("ShowMissionSituation")

local PROTECTED_NAMES = {
	BitKaisenGui = true,
	MainPanel = true,
	LogContainer = true,
	LifeLog = true,
	NavPanel = true,
	ProfileCard = true,
	AssetsOverlay = true,
	MajorPopupOverlay = true,
	MajorPopupWindow = true,
}

local ROOT_NAME_HINTS = {
	"EVENT",
	"CHOICE",
	"SITUATION",
	"MISSION",
	"LIFE",
	"POPUP",
	"OVERLAY",
	"MODAL",
	"WINDOW",
}

local function normalizeText(value)
	return string.lower(tostring(value or ""))
end

local function containsText(root, wantedText)
	local wanted = normalizeText(wantedText)
	if wanted == "" then
		return false
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			local text = normalizeText(descendant.Text)
			if text == wanted or string.find(text, wanted, 1, true) then
				return true
			end
		end
	end
	return false
end

local function countMatchingButtons(root, options)
	local count = 0
	local seen = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextButton") then
			local buttonText = normalizeText(descendant.Text)
			for _, option in ipairs(options or {}) do
				local optionText = normalizeText(option and option.Text)
				if optionText ~= "" and not seen[optionText] and (buttonText == optionText or string.find(buttonText, optionText, 1, true)) then
					seen[optionText] = true
					count += 1
					break
				end
			end
		end
	end
	return count
end

local function hasLifeEventLabel(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			local text = normalizeText(descendant.Text)
			if text == "life event" then
				return true
			end
		end
	end
	return false
end

local function hasChoiceButtons(root)
	local count = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextButton") and descendant.Visible then
			count += 1
			if count >= 2 then
				return true
			end
		end
	end
	return false
end

local function nameLooksLikePopup(name)
	local upperName = string.upper(tostring(name or ""))
	for _, hint in ipairs(ROOT_NAME_HINTS) do
		if string.find(upperName, hint, 1, true) then
			return true
		end
	end
	return false
end

local function getCandidateRoot(guiObject)
	local current = guiObject
	local best = nil
	while current and current ~= playerGui do
		if current:IsA("GuiObject") then
			local parent = current.Parent
			local isProtected = PROTECTED_NAMES[current.Name] == true
			local looksLikePopup = nameLooksLikePopup(current.Name)
			local bigEnough = current.AbsoluteSize.X >= 300 and current.AbsoluteSize.Y >= 180
			local directlyUnderScreenGui = parent and parent:IsA("ScreenGui")
			local underOverlay = parent and parent:IsA("GuiObject") and nameLooksLikePopup(parent.Name)
			if not isProtected and bigEnough and (looksLikePopup or directlyUnderScreenGui or underOverlay) then
				best = current
			end
		end
		if current.Parent and current.Parent:IsA("ScreenGui") then
			break
		end
		current = current.Parent
	end
	return best
end

local function gatherPopupCandidates(eventData)
	local title = tostring(eventData and eventData.Title or eventData and eventData.MissionTitle or "")
	local options = eventData and eventData.Options or {}
	local candidates = {}
	local added = {}
	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiObject") and descendant.Visible then
			local matchesTitle = containsText(descendant, title)
			local matchesButtons = countMatchingButtons(descendant, options) >= math.min(2, #options)
			if matchesTitle and matchesButtons and hasChoiceButtons(descendant) then
				local root = getCandidateRoot(descendant)
				if root and not added[root] then
					added[root] = true
					table.insert(candidates, root)
				end
			end
		end
	end
	return candidates
end

local function candidateScore(root)
	local score = 0
	local name = string.upper(tostring(root.Name or ""))
	if hasLifeEventLabel(root) then
		score += 1000
	end
	if string.find(name, "LIFE", 1, true) then
		score += 80
	end
	if string.find(name, "EVENT", 1, true) then
		score += 60
	end
	if string.find(name, "CHOICE", 1, true) then
		score += 50
	end
	if string.find(name, "MISSION", 1, true) then
		score += 10
	end
	if root:IsA("GuiObject") then
		score += root.ZIndex
		score += math.floor(root.AbsoluteSize.X / 100)
		score += math.floor(root.AbsoluteSize.Y / 100)
	end
	return score
end

local function cleanupDuplicatePopups(eventData)
	local candidates = gatherPopupCandidates(eventData)
	if #candidates <= 1 then
		return
	end
	table.sort(candidates, function(a, b)
		return candidateScore(a) > candidateScore(b)
	end)
	local keep = candidates[1]
	for index = 2, #candidates do
		local candidate = candidates[index]
		if candidate and candidate.Parent and candidate ~= keep and PROTECTED_NAMES[candidate.Name] ~= true then
			candidate:Destroy()
		end
	end
end

showMissionSituation.OnClientEvent:Connect(function(eventData)
	task.defer(function()
		cleanupDuplicatePopups(eventData)
	end)
	task.delay(0.08, function()
		cleanupDuplicatePopups(eventData)
	end)
	task.delay(0.25, function()
		cleanupDuplicatePopups(eventData)
	end)
	task.delay(0.6, function()
		cleanupDuplicatePopups(eventData)
	end)
end)

RunService.Heartbeat:Connect(function()
end)
