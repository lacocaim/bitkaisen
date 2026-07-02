local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cache = {}

local function get(name: string): Instance
	if cache[name] and cache[name].Parent then
		return cache[name]
	end
	local remote = ReplicatedStorage:WaitForChild(name, 10)
	if remote then
		cache[name] = remote
	end
	return remote
end

return {
	get = get,

	updateLifeEvent = function() return get("UpdateLifeEvent") end,
	showMajorPopup = function() return get("ShowMajorPopup") end,
	showMissionSituation = function() return get("ShowMissionSituation") end,
	missionChoice = function() return get("MissionChoice") end,

	getMissionBoard = function() return get("GetMissionBoard") end,
	getActivityList = function() return get("GetActivityList") end,
	getJobs = function() return get("GetJobs") end,
	jobAction = function() return get("JobAction") end,
	getRelationships = function() return get("GetRelationships") end,
	relationshipAction = function() return get("RelationshipAction") end,
	getWorldHistory = function() return get("GetWorldHistory") end,
	getTitles = function() return get("GetTitles") end,
	getDevTools = function() return get("GetDevTools") end,
	devToolsAction = function() return get("DevToolsAction") end,
	getAssets = function() return get("GetAssets") end,
	assetAction = function() return get("AssetAction") end,
	getBlackMarket = function() return get("GetBlackMarket") end,
	blackMarketAction = function() return get("BlackMarketAction") end,
	getCult = function() return get("GetCult") end,
	cultAction = function() return get("CultAction") end,
	getCultWar = function() return get("GetCultWar") end,
	cultWarAction = function() return get("CultWarAction") end,
	getClanWar = function() return get("GetClanWar") end,
	clanWarAction = function() return get("ClanWarAction") end,
	getDomain = function() return get("GetDomain") end,
	domainAction = function() return get("DomainAction") end,
	getGodMode = function() return get("GetGodMode") end,
	godModeAction = function() return get("GodModeAction") end,
	getRivals = function() return get("GetRivals") end,
	rivalAction = function() return get("RivalAction") end,
	getSuccessorOptions = function() return get("GetSuccessorOptions") end,
	chooseSuccessor = function() return get("ChooseSuccessor") end,
	getCombatState = function() return get("GetCombatState") end,
	combatAction = function() return get("CombatAction") end,
	combatStateUpdate = function() return get("CombatStateUpdate") end,
	combatMinigameResult = function() return get("CombatMinigameResult") end,
	updateSettingsEvent = function() return get("UpdateSettingsEvent") end,
	getSaveSlots = function() return get("GetSaveSlots") end,
	selectSaveSlot = function() return get("SelectSaveSlot") end,
	createSaveSlot = function() return get("CreateSaveSlot") end,
	deleteSaveSlot = function() return get("DeleteSaveSlot") end,
	getAchievements = function() return get("GetAchievements") end,
	claimAchievement = function() return get("ClaimAchievement") end,
	redeemCode = function() return get("RedeemCode") end,
	getCodeGate = function() return get("GetCodeGate") end,
	getBindingVows = function() return get("GetBindingVows") end,
	bindingVowAction = function() return get("BindingVowAction") end,
	getDailyLogin = function() return get("GetDailyLogin") end,
	claimDailyLogin = function() return get("ClaimDailyLogin") end,
	getFreeReward = function() return get("GetFreeReward") end,
	claimFreeReward = function() return get("ClaimFreeReward") end,
	getAFKStabilization = function() return get("GetAFKStabilization") end,
	afkStabilizationAction = function() return get("AFKStabilizationAction") end,
	afkStabilizationUpdate = function() return get("AFKStabilizationUpdate") end,
	initiateGift = function() return get("InitiateGift") end,
	promptGiftPurchase = function() return get("PromptGiftPurchase") end,
	markTutorialSeen = function() return get("MarkTutorialSeen") end,
	submitCharacterCustomization = function() return get("SubmitCharacterCustomization") end,
	getMentor = function() return get("GetMentor") end,
	mentorAction = function() return get("MentorAction") end,
	startMinigame = function() return get("StartMinigame") end,
	completeMinigame = function() return get("CompleteMinigame") end,
	promptGroupJoin = function() return get("PromptGroupJoin") end,
	claimGroupJoinReward = function() return get("ClaimGroupJoinReward") end,
	clearPendingMission = function() return get("ClearPendingMission") end,
}
