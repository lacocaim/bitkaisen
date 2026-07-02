-- ModuleScript: BK_Remotes
-- Location: ServerScriptService.BitKaisenServer
-- Purpose:
--   Owns every BitKaisen RemoteEvent / RemoteFunction.
--   Remotes exist even if GameManager later hits a syntax/runtime error.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BK_Remotes = {}

local REMOTE_DEFINITIONS = {
	PromptGroupJoin = "RemoteEvent",
	ClaimGroupJoinReward = "RemoteEvent",

	UpdateLifeEvent = "RemoteEvent",
	ShowMajorPopup = "RemoteEvent",
	ShowMissionSituation = "RemoteEvent",
	MissionChoice = "RemoteEvent",
	ClearPendingMission = "RemoteEvent",

	StartMinigame = "RemoteEvent",
	CompleteMinigame = "RemoteEvent",

	GetCombatState = "RemoteFunction",
	CombatAction = "RemoteEvent",
	CombatStateUpdate = "RemoteEvent",
	CombatMinigameResult = "RemoteEvent",

	GetMissionBoard = "RemoteFunction",
	GetActivityList = "RemoteFunction",
	GetJobs = "RemoteFunction",
	JobAction = "RemoteEvent",
	TestPurchase = "RemoteEvent",
	GetRelationships = "RemoteFunction",
	RelationshipAction = "RemoteEvent",
	GetWorldHistory = "RemoteFunction",
	GetTitles = "RemoteFunction",
	GetDevTools = "RemoteFunction",
	DevToolsAction = "RemoteEvent",

	GetAssets = "RemoteFunction",
	AssetAction = "RemoteEvent",

	GetBlackMarket = "RemoteFunction",
	BlackMarketAction = "RemoteEvent",

	-- Cursed Cult System
	GetCult = "RemoteFunction",
	CultAction = "RemoteEvent",

	-- Update 13: Clan War System
	GetClanWar = "RemoteFunction",
	ClanWarAction = "RemoteEvent",

	-- Update 14: Domain Expansion
	GetDomain = "RemoteFunction",
	DomainAction = "RemoteEvent",

	-- God Mode premium controls
	GetGodMode = "RemoteFunction",
	GodModeAction = "RemoteEvent",

	-- Update 15: Rivals and Reputation
	GetRivals = "RemoteFunction",
	RivalAction = "RemoteEvent",

	GetSuccessorOptions = "RemoteFunction",
	ChooseSuccessor = "RemoteEvent",

	UpdateSettingsEvent = "RemoteEvent",

	GetSaveSlots = "RemoteFunction",
	SelectSaveSlot = "RemoteEvent",
	CreateSaveSlot = "RemoteEvent",
	DeleteSaveSlot = "RemoteEvent",

	GetAchievements = "RemoteFunction",
	ClaimAchievement = "RemoteEvent",

	RedeemCode = "RemoteFunction",
	GetCodeGate = "RemoteFunction",

	GetBindingVows = "RemoteFunction",
	BindingVowAction = "RemoteEvent",

	-- Update 6.2: Daily Login Rewards
	GetDailyLogin = "RemoteFunction",
	ClaimDailyLogin = "RemoteEvent",

	-- Free rewards button
	GetFreeReward = "RemoteFunction",
	ClaimFreeReward = "RemoteFunction",

	-- AFK Stabilization
	GetAFKStabilization = "RemoteFunction",
	AFKStabilizationAction = "RemoteEvent",
	AFKStabilizationUpdate = "RemoteEvent",

	-- Gift gamepass developer-product flow
	InitiateGift = "RemoteEvent",
	PromptGiftPurchase = "RemoteEvent",

	-- Update 6.2: First-time tutorial persistence
	MarkTutorialSeen = "RemoteEvent",

	-- Update 6: Character Customization
	SubmitCharacterCustomization = "RemoteFunction",

	-- Jujutsu Mentor
	GetMentor = "RemoteFunction",
	MentorAction = "RemoteEvent",

	-- Cemetery of Lives
	GetPastLives = "RemoteFunction",

	-- Weekly Challenges
	GetChallenges = "RemoteFunction",
	ChallengeCompleted = "RemoteEvent",
}

local remoteCache = {}
local initialized = false

local function isCorrectClass(instance, className)
	if className == "RemoteEvent" then
		return instance:IsA("RemoteEvent")
	elseif className == "RemoteFunction" then
		return instance:IsA("RemoteFunction")
	end

	return false
end

function BK_Remotes.Ensure(name, className)
	local existing = ReplicatedStorage:FindFirstChild(name)

	if existing then
		if isCorrectClass(existing, className) then
			remoteCache[name] = existing
			return existing
		end

		warn("[BK_Remotes] Replacing wrong remote class for " .. tostring(name) .. ". Expected " .. tostring(className) .. ", got " .. tostring(existing.ClassName) .. ".")
		existing:Destroy()
	end

	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage

	remoteCache[name] = remote
	return remote
end

function BK_Remotes.Init()
	if _G.__BK_RemotesInitialized then
		return
	end
	if initialized then
		return
	end
	_G.__BK_RemotesInitialized = true
	initialized = true

	for name, className in pairs(REMOTE_DEFINITIONS) do
		BK_Remotes.Ensure(name, className)
	end

	if game:GetService("RunService"):IsStudio() then print("[BK_Remotes] Loaded " .. tostring(#BK_Remotes.ListNames()) .. " remotes.") end
end

function BK_Remotes.Get(name)
	if remoteCache[name] and remoteCache[name].Parent then
		return remoteCache[name]
	end

	local className = REMOTE_DEFINITIONS[name]
	if not className then
		warn("[BK_Remotes] Unknown remote requested: " .. tostring(name))
		return nil
	end

	return BK_Remotes.Ensure(name, className)
end

function BK_Remotes.All()
	BK_Remotes.Init()

	local remotes = {}
	for name in pairs(REMOTE_DEFINITIONS) do
		remotes[name] = BK_Remotes.Get(name)
	end

	return remotes
end

function BK_Remotes.ListNames()
	local names = {}
	for name in pairs(REMOTE_DEFINITIONS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return BK_Remotes
