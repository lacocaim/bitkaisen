local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local function setCoreGui(coreType, enabled)
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, enabled)
		end)
		if ok then return end
		task.wait(0.5)
	end
end

local function setChatConfigs(enabled)
	pcall(function()
		local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if chatWindow then
			chatWindow.Enabled = enabled
		end
	end)
	pcall(function()
		local bubbleChat = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
		if bubbleChat then
			bubbleChat.Enabled = enabled
		end
	end)
end

-- Chat starts OFF everywhere (the original BitKaisen behavior)...
setCoreGui(Enum.CoreGuiType.Chat, false)
setChatConfigs(false)

-- ...and comes back ON only inside a Public world (Multiplayer Fase 8,
-- the Fair Play Doctrine social layer): the first UpdateLifeEvent whose stats say
-- WorldMode == "Public" flips it for the rest of the session. Private
-- sessions never see it -- the classic solo game stays chat-free.
local chatEnabled = false
task.spawn(function()
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 30)
	if not updateLifeEvent then
		return
	end
	updateLifeEvent.OnClientEvent:Connect(function(stats)
		if chatEnabled or typeof(stats) ~= "table" or stats.WorldMode ~= "Public" then
			return
		end
		chatEnabled = true
		setCoreGui(Enum.CoreGuiType.Chat, true)
		setChatConfigs(true)
	end)
end)

-- Public chat identity: color each sender's name by their LifePath and tag
-- their cell, read from player attributes kept fresh by the server
-- (fireLifeUpdate sets BKChatName/BKChatPath; BK_CellService sets
-- BKChatCell). Registered unconditionally -- it only ever fires once chat
-- is enabled, i.e. in Public.
local PATH_COLORS = {
	["Jujutsu High"] = "#68b2f6",
	["Clan Founder"] = "#ffcf5e",
	["Curse User"] = "#eb5268",
	["Cursed Spirit"] = "#a065f4",
	["Rogue Sorcerer"] = "#f48e56",
	["Unregistered Sorcerer"] = "#70e099",
}
local DEFAULT_PATH_COLOR = "#aea8bf"

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	if not source then
		return nil
	end
	local sender = Players:GetPlayerByUserId(source.UserId)
	if not sender then
		return nil
	end
	local chatName = sender:GetAttribute("BKChatName")
	if typeof(chatName) ~= "string" or chatName == "" then
		return nil
	end
	local path = sender:GetAttribute("BKChatPath")
	local color = PATH_COLORS[path] or DEFAULT_PATH_COLOR
	local cell = sender:GetAttribute("BKChatCell")
	local cellTag = (typeof(cell) == "string" and cell ~= "") and ("[" .. cell .. "] ") or ""

	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = "<font color='" .. color .. "'>" .. cellTag .. chatName .. ":</font>"
	return properties
end

-- Remove the Roblox "Reset Character" / respawn option. This is a life-sim with
-- no physical character, so respawning has no meaning. SetCore can fail before
-- CoreScripts load, so retry until it sticks.
task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		if ok then return end
		task.wait(0.5)
	end
end)
