-- Multiplayer Fase 6B/6C: live duel HUD + incoming-challenge modal. Shared
-- by BOTH clients (registered in BitKaisenClient and BitKaisenMobileClient,
-- same precedent as SettingsPanel) -- it scales via responsiveScale and has
-- no PC-only input assumptions. Not nav-routed: it force-opens the moment a
-- DuelStateUpdate for you arrives (duelist or spectator), and the invite
-- modal opens on DuelInvite. All state comes from BK_DuelService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key, fallback) return BitKaisenLocale.tOrFallback(_L, "duel." .. key, nil, fallback) end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local duelAction = ReplicatedStorage:WaitForChild("DuelAction")
local duelStateUpdate = ReplicatedStorage:WaitForChild("DuelStateUpdate")
local duelInvite = ReplicatedStorage:WaitForChild("DuelInvite")

local THEME = {
	Bg = Color3.fromRGB(13, 13, 20),
	Panel = Color3.fromRGB(23, 22, 33),
	Panel2 = Color3.fromRGB(30, 28, 42),
	Stroke = Color3.fromRGB(83, 67, 104),
	Text = Color3.fromRGB(244, 240, 250),
	SubText = Color3.fromRGB(174, 168, 191),
	Gold = Color3.fromRGB(255, 207, 94),
	Red = Color3.fromRGB(235, 82, 104),
	Purple = Color3.fromRGB(160, 101, 244),
	Green = Color3.fromRGB(112, 224, 153),
	Blue = Color3.fromRGB(104, 178, 246),
	HPYou = Color3.fromRGB(112, 224, 153),
	HPFoe = Color3.fromRGB(235, 82, 104),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenDuelGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 905
gui.Enabled = false
gui.Parent = playerGui

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function stroke(obj, color)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Stroke
	s.Thickness = 1
	s.Transparency = 0.12
	s.Parent = obj
	return s
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = props.pos or UDim2.new(0, 0, 0, 0)
	l.Size = props.size or UDim2.new(1, 0, 0, 20)
	l.Text = props.text or ""
	l.TextColor3 = props.color or THEME.Text
	l.TextSize = props.textSize or 13
	l.TextWrapped = props.wrap == true
	l.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Font = props.font or Enum.Font.GothamBold
	l.ZIndex = (parent.ZIndex or 1) + 1
	l.Parent = parent
	return l
end

----------------------------------------------------------------
-- Duel window
----------------------------------------------------------------

local overlay = Instance.new("Frame")
overlay.Name = "DuelOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 905
overlay.Parent = gui

local window = Instance.new("Frame")
window.Name = "DuelWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = THEME.Bg
window.BorderSizePixel = 0
window.ZIndex = 906
window.Parent = overlay
responsiveScale.attach(window, 760, 520)
corner(window, 12)
stroke(window, THEME.Purple)

local titleLabel = label(window, { pos = UDim2.fromOffset(20, 14), size = UDim2.new(1, -40, 0, 28), text = "⚔ " .. _g("title", "LIVE DUEL"), color = THEME.Gold, textSize = 20, font = Enum.Font.GothamBlack })

local turnLabel = label(window, { pos = UDim2.fromOffset(20, 44), size = UDim2.new(1, -40, 0, 22), text = "", color = THEME.SubText, textSize = 13, xAlign = Enum.TextXAlignment.Center })

-- One fighter column (name, spec, HP bar, CE) -- built twice, you vs foe.
local function buildFighterBox(xScale, hpColor)
	local box = Instance.new("Frame")
	box.Position = UDim2.new(xScale, 20, 0, 74)
	box.Size = UDim2.new(0.5, -30, 0, 108)
	box.BackgroundColor3 = THEME.Panel
	box.BorderSizePixel = 0
	box.ZIndex = 907
	box.Parent = window
	corner(box, 10)
	stroke(box)

	local nameL = label(box, { pos = UDim2.fromOffset(12, 8), size = UDim2.new(1, -24, 0, 22), text = "-", color = THEME.Text, textSize = 15, font = Enum.Font.GothamBlack })
	local specL = label(box, { pos = UDim2.fromOffset(12, 30), size = UDim2.new(1, -24, 0, 18), text = "", color = THEME.Purple, textSize = 11 })

	local hpTrack = Instance.new("Frame")
	hpTrack.Position = UDim2.fromOffset(12, 54)
	hpTrack.Size = UDim2.new(1, -24, 0, 14)
	hpTrack.BackgroundColor3 = THEME.Panel2
	hpTrack.BorderSizePixel = 0
	hpTrack.ZIndex = 908
	hpTrack.Parent = box
	corner(hpTrack, 7)

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = hpColor
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 909
	hpFill.Parent = hpTrack
	corner(hpFill, 7)

	local hpL = label(box, { pos = UDim2.fromOffset(12, 70), size = UDim2.new(1, -24, 0, 16), text = "", color = THEME.SubText, textSize = 11 })
	local ceL = label(box, { pos = UDim2.fromOffset(12, 86), size = UDim2.new(1, -24, 0, 16), text = "", color = THEME.Blue, textSize = 11 })

	return { Box = box, Name = nameL, Spec = specL, HPFill = hpFill, HP = hpL, CE = ceL }
end

local youBox = buildFighterBox(0, THEME.HPYou)
local foeBox = buildFighterBox(0.5, THEME.HPFoe)

local logFrame = Instance.new("Frame")
logFrame.Position = UDim2.new(0, 20, 0, 192)
logFrame.Size = UDim2.new(1, -40, 0, 168)
logFrame.BackgroundColor3 = THEME.Panel
logFrame.BorderSizePixel = 0
logFrame.ZIndex = 907
logFrame.Parent = window
corner(logFrame, 10)
stroke(logFrame)

local logLabel = label(logFrame, { pos = UDim2.fromOffset(12, 8), size = UDim2.new(1, -24, 1, -16), text = "", color = THEME.SubText, textSize = 12, wrap = true })
logLabel.TextYAlignment = Enum.TextYAlignment.Top

local buttonRow = Instance.new("Frame")
buttonRow.Position = UDim2.new(0, 20, 1, -140)
buttonRow.Size = UDim2.new(1, -40, 0, 54)
buttonRow.BackgroundTransparency = 1
buttonRow.ZIndex = 907
buttonRow.Parent = window

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Padding = UDim.new(0, 10)
rowLayout.Parent = buttonRow

local actionButtons = {}
local function makeActionButton(order, text, color, actionId)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.new(0.25, -8, 1, 0)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = THEME.Text
	btn.TextSize = 13
	btn.TextWrapped = true
	btn.Font = Enum.Font.GothamBlack
	btn.AutoButtonColor = true
	btn.ZIndex = 908
	btn.Parent = buttonRow
	corner(btn, 10)
	btn.Activated:Connect(function()
		duelAction:FireServer(actionId, {})
	end)
	actionButtons[actionId] = btn
	return btn
end

makeActionButton(1, "👊 " .. _g("attack", "ATTACK"), THEME.Red, "attack")
makeActionButton(2, "🌀 " .. _g("technique", "TECHNIQUE"), THEME.Purple, "technique")
makeActionButton(3, "🛡 " .. _g("defend", "DEFEND"), THEME.Blue, "defend")
makeActionButton(4, "🏳 " .. _g("flee", "CONCEDE"), THEME.Panel2, "flee")

local statusLabel = label(window, { pos = UDim2.new(0, 20, 1, -78), size = UDim2.new(1, -40, 0, 24), text = "", color = THEME.Gold, textSize = 14, xAlign = Enum.TextXAlignment.Center, font = Enum.Font.GothamBlack })

local leaveButton = Instance.new("TextButton")
leaveButton.Position = UDim2.new(0.5, -80, 1, -48)
leaveButton.Size = UDim2.fromOffset(160, 34)
leaveButton.BackgroundColor3 = THEME.Panel2
leaveButton.BorderSizePixel = 0
leaveButton.Text = _g("close", "CLOSE")
leaveButton.TextColor3 = THEME.Text
leaveButton.TextSize = 13
leaveButton.Font = Enum.Font.GothamBlack
leaveButton.Visible = false
leaveButton.ZIndex = 908
leaveButton.Parent = window
corner(leaveButton, 8)

----------------------------------------------------------------
-- Invite modal
----------------------------------------------------------------

local inviteOverlay = Instance.new("Frame")
inviteOverlay.Name = "DuelInviteOverlay"
inviteOverlay.Size = UDim2.fromScale(1, 1)
inviteOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
inviteOverlay.BackgroundTransparency = 0.45
inviteOverlay.BorderSizePixel = 0
inviteOverlay.Visible = false
inviteOverlay.ZIndex = 910
inviteOverlay.Parent = gui

local inviteCard = Instance.new("Frame")
inviteCard.AnchorPoint = Vector2.new(0.5, 0.5)
inviteCard.Position = UDim2.fromScale(0.5, 0.5)
inviteCard.BackgroundColor3 = THEME.Bg
inviteCard.BorderSizePixel = 0
inviteCard.ZIndex = 911
inviteCard.Parent = inviteOverlay
responsiveScale.attach(inviteCard, 420, 240)
corner(inviteCard, 12)
stroke(inviteCard, THEME.Gold)

local inviteTitle = label(inviteCard, { pos = UDim2.fromOffset(20, 16), size = UDim2.new(1, -40, 0, 26), text = "⚔ " .. _g("invite_title", "DUEL CHALLENGE"), color = THEME.Gold, textSize = 18, font = Enum.Font.GothamBlack })
local inviteBody = label(inviteCard, { pos = UDim2.fromOffset(20, 48), size = UDim2.new(1, -40, 0, 62), text = "", color = THEME.Text, textSize = 14, wrap = true })
local inviteTimer = label(inviteCard, { pos = UDim2.fromOffset(20, 112), size = UDim2.new(1, -40, 0, 18), text = "", color = THEME.SubText, textSize = 12 })

local function inviteButton(xScale, text, color, actionId)
	local btn = Instance.new("TextButton")
	btn.Position = UDim2.new(xScale, 20, 1, -66)
	btn.Size = UDim2.new(0.5, -30, 0, 46)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = THEME.Text
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBlack
	btn.ZIndex = 912
	btn.Parent = inviteCard
	corner(btn, 10)
	btn.Activated:Connect(function()
		duelAction:FireServer(actionId, {})
		inviteOverlay.Visible = false
	end)
	return btn
end

inviteButton(0, "✔ " .. _g("accept", "ACCEPT"), THEME.Green, "accept")
inviteButton(0.5, "✘ " .. _g("decline", "DECLINE"), THEME.Red, "decline")

----------------------------------------------------------------
-- State handling
----------------------------------------------------------------

local currentState = nil
local turnDeadlineClock = 0
local inviteExpiresAt = 0
local isSpectating = false

local function render(state)
	currentState = state
	local you, foe
	if state.A.UserId == player.UserId then
		you, foe = state.A, state.B
		isSpectating = false
	elseif state.B.UserId == player.UserId then
		you, foe = state.B, state.A
		isSpectating = false
	else
		you, foe = state.A, state.B
		isSpectating = true
	end

	titleLabel.Text = "⚔ " .. _g("title", "LIVE DUEL") .. (isSpectating and "  👁 " .. _g("spectating", "SPECTATING") or "") .. ((state.StakesMultiplier or 1) > 1 and "  🔥 REVANCHA" or "")

	local function fillBox(box, side, prefix)
		box.Name.Text = prefix .. side.Name
		box.Spec.Text = "🧬 " .. tostring(side.Spec or "Offensive") .. (side.Defending and "   🛡" or "")
		box.HPFill.Size = UDim2.fromScale(math.clamp(side.HP / math.max(1, side.MaxHP), 0, 1), 1)
		box.HP.Text = "HP " .. tostring(side.HP) .. "/" .. tostring(side.MaxHP)
		box.CE.Text = "CE " .. tostring(side.CE)
	end
	fillBox(youBox, you, isSpectating and "" or "👤 ")
	fillBox(foeBox, foe, isSpectating and "" or "🎯 ")

	logLabel.Text = table.concat(state.Log or {}, "\n")

	local finished = state.Phase == "finished"
	local myTurn = not finished and not isSpectating and state.TurnUserId == player.UserId
	for actionId, btn in pairs(actionButtons) do
		btn.Visible = not isSpectating and not finished
		btn.AutoButtonColor = myTurn
		btn.BackgroundTransparency = myTurn and 0 or 0.55
		local _ = actionId
	end

	if finished then
		local winnerSide = (state.Winner == state.A.UserId) and state.A or state.B
		statusLabel.Text = "🏆 " .. winnerSide.Name .. " " .. _g("wins", "WINS THE DUEL")
		leaveButton.Visible = true
		turnLabel.Text = ""
	else
		leaveButton.Visible = isSpectating
		turnDeadlineClock = os.clock() + (tonumber(state.TurnSecondsLeft) or 0)
		statusLabel.Text = myTurn and ("▶ " .. _g("your_turn", "YOUR TURN")) or ""
	end

	overlay.Visible = true
	gui.Enabled = true
end

local function closeDuelView()
	overlay.Visible = false
	currentState = nil
	if not inviteOverlay.Visible then
		gui.Enabled = false
	end
end

leaveButton.Activated:Connect(function()
	if isSpectating and currentState and currentState.Phase == "active" then
		duelAction:FireServer("stop_spectate", {})
	end
	closeDuelView()
end)

duelStateUpdate.OnClientEvent:Connect(function(state)
	if typeof(state) ~= "table" then
		return
	end
	render(state)
	if state.Phase == "finished" then
		task.delay(8, function()
			if currentState and currentState.DuelId == state.DuelId and currentState.Phase == "finished" then
				closeDuelView()
			end
		end)
	end
end)

duelInvite.OnClientEvent:Connect(function(invite)
	if typeof(invite) ~= "table" then
		return
	end
	inviteBody.Text = tostring(invite.FromName) .. " (" .. tostring(invite.FromGrade) .. ") " .. _g("invite_body", "challenges you to a live duel.") .. (invite.IsRematch and "  🔥 REVANCHA -- " .. _g("invite_stakes", "higher stakes!") or "")
	inviteExpiresAt = tonumber(invite.ExpiresAt) or (os.time() + 30)
	inviteOverlay.Visible = true
	gui.Enabled = true
end)

-- One light ticker drives both countdowns (turn clock + invite expiry).
RunService.Heartbeat:Connect(function()
	if overlay.Visible and currentState and currentState.Phase == "active" then
		local left = math.max(0, math.ceil(turnDeadlineClock - os.clock()))
		local turnName = (currentState.TurnUserId == currentState.A.UserId) and currentState.A.Name or currentState.B.Name
		turnLabel.Text = "⏱ " .. turnName .. " -- " .. tostring(left) .. "s"
	end
	if inviteOverlay.Visible then
		local left = inviteExpiresAt - os.time()
		if left <= 0 then
			inviteOverlay.Visible = false
			if not overlay.Visible then
				gui.Enabled = false
			end
		else
			inviteTimer.Text = "⏳ " .. tostring(left) .. "s"
		end
	end
end)

local function init()
	-- Everything is event-driven (DuelStateUpdate / DuelInvite); nothing to
	-- do at boot beyond having the connections above live.
	local _ = inviteTitle
end

return { init = init }
