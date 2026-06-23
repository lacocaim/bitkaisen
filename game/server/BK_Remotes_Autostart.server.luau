-- Purpose:
--   Starts the remote layer before/without GameManager.
--   This prevents every UI script from infinite-yielding if GameManager breaks.

local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("BitKaisenServer")
local BK_Remotes = require(serverFolder:WaitForChild("BK_Remotes"))

BK_Remotes.Init()

print("[BK_Remotes_Autostart] Remotes ready.")
