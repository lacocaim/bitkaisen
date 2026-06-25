local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local function disableCoreGui(coreType)
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, false)
		end)
		if ok then return end
		task.wait(0.5)
	end
end

disableCoreGui(Enum.CoreGuiType.Chat)

pcall(function()
	local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if chatWindow then
		chatWindow.Enabled = false
	end
end)

pcall(function()
	local bubbleChat = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
	if bubbleChat then
		bubbleChat.Enabled = false
	end
end)
