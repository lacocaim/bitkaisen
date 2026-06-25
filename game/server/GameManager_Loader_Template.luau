-- Purpose:
-- This is the future tiny GameManager after the split is complete.
-- DO NOT replace your live GameManager with this yet unless the modules are fully migrated.

local ServerScriptService = game:GetService("ServerScriptService")

local BK_Server = ServerScriptService:WaitForChild("BitKaisenServer")

local context = {}

local loadOrder = {
	"BK_Remotes",
	"BK_PlayerData",
	"BK_RuntimeBridge",
	"BK_CurseService",
	"BK_MissionService",
	"BK_ActivityService",
	"BK_RelationshipService",
	"BK_AssetService",
	"BK_DojoService",
	"BK_LegacyService",
	"BK_CommerceService",
	"BK_CodeService",
	"BK_AchievementService",
	"BK_DevCommands",
}

for _, moduleName in ipairs(loadOrder) do
	local moduleScript = BK_Server:WaitForChild(moduleName)
	local module = require(moduleScript)

	context[moduleName] = module

	if type(module.Init) == "function" then
		module.Init(context)
	end
end

if game:GetService("RunService"):IsStudio() then print("[GameManager_Loader_Template] BitKaisen modular server loaded.") end
