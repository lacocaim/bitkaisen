-- Purpose:
--   Starts the remote layer before/without GameManager.
--   This prevents every UI script from infinite-yielding if GameManager breaks.

if _G.__BK_Remotes_AutostartLoaded then
	return
end
_G.__BK_Remotes_AutostartLoaded = true

local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("BitKaisenServer")
local BK_Remotes = require(serverFolder:WaitForChild("BK_Remotes"))

BK_Remotes.Init()

if game:GetService("RunService"):IsStudio() then print("[BK_Remotes_Autostart] Remotes ready.") end
