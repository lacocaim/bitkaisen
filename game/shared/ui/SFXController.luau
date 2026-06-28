local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sounds = {} :: { [string]: Sound }

local function cloneSound(soundName: string): Sound?
	local sfxFolder = ReplicatedStorage:FindFirstChild("BitKaisenSFX")
	if not sfxFolder then return nil end

	local source = sfxFolder:FindFirstChild(soundName)
	if not source or not source:IsA("Sound") then return nil end

	local sound = source:Clone()
	sound.Name = "BitKaisen_" .. soundName
	sound.Volume = source.Volume
	sound.Parent = SoundService
	return sound
end

local function play(soundName: string)
	local sound = sounds[soundName]
	if not sound then return end
	sound.TimePosition = 0
	sound:Play()
end

local function hookButton(button: Instance)
	if not button:IsA("TextButton") and not button:IsA("ImageButton") then return end
	if button:GetAttribute("BitKaisenSFXHooked") then return end
	button:SetAttribute("BitKaisenSFXHooked", true)

	button.Activated:Connect(function()
		local text = ""
		if button:IsA("TextButton") then text = string.upper(button.Text or "") end

		if string.find(text, "CLAIM") or string.find(text, "REWARD") or string.find(text, "BUY") then
			play("Success")
		elseif string.find(text, "CLOSE") or string.find(text, "X") then
			play("ChoiceSelect")
		else
			play("ButtonClick")
		end
	end)
end

local function scanGui(root: Instance)
	for _, descendant in ipairs(root:GetDescendants()) do
		hookButton(descendant)
	end
end

local function watchGui(root: Instance)
	scanGui(root)
	root.DescendantAdded:Connect(function(descendant)
		task.wait()
		hookButton(descendant)
	end)
end

local function init()
	sounds.ButtonClick = cloneSound("ButtonClick")
	sounds.PopupOpen = cloneSound("PopupOpen")
	sounds.ChoiceSelect = cloneSound("ChoiceSelect")
	sounds.Success = cloneSound("Success")
	sounds.Error = cloneSound("Error")

	for _, gui in ipairs(playerGui:GetChildren()) do
		watchGui(gui)
	end

	playerGui.ChildAdded:Connect(function(gui)
		task.wait()
		watchGui(gui)
	end)

	local showMajorPopup = ReplicatedStorage:FindFirstChild("ShowMajorPopup")
	if showMajorPopup and showMajorPopup:IsA("RemoteEvent") then
		showMajorPopup.OnClientEvent:Connect(function()
			play("PopupOpen")
		end)
	end

	local showMissionSituation = ReplicatedStorage:FindFirstChild("ShowMissionSituation")
	if showMissionSituation and showMissionSituation:IsA("RemoteEvent") then
		showMissionSituation.OnClientEvent:Connect(function()
			play("PopupOpen")
		end)
	end

	if not _G.BitKaisenPlaySFX then
		_G.BitKaisenPlaySFX = play
	end
end

return { init = init }
