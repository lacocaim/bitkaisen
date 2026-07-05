-- Mobile counterpart of FirstTimeGuidancePanel.luau (PC). Same 20-step
-- onboarding tutorial (Welcome, +AGE, Log, Profile, Quick Access, one step
-- per navRegistry category, How To Win, Finish) sharing the exact same step
-- content via guidanceSteps.luau -- only target resolution differs, since
-- Mobile's dashboard (mobileShell.luau) uses different root Frame names than
-- PC's (see resolveTarget below).
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local responsiveScale = require("@ui/responsiveScale")
local FocusHighlight = require("@ui/FocusHighlight")
local guidanceSteps = require("@ui/guidanceSteps")
local uiState = require("@ui-state/uiState")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

local player = Players.LocalPlayer

local GUI_NAME = "BitKaisenMobileFirstTimeGuidanceUI"
local MAIN_GUI_NAME = "MobileGui"

-- Mobile's root Frame names differ from PC's for the same visual elements
-- (see mobileShell.luau: MobileAgeButton() -> "AgeUpOuter", MobileProfileHeader()
-- -> "ProfileHeader"; MobileLifeLog() already reuses "LogContainer").
local TARGET_PATH_MAP = {
	ActionRow = "AgeUpOuter",
	ProfileCard = "ProfileHeader",
	LogContainer = "LogContainer",
}

-- Set by init() so the module-level `replay` export (used by
-- MobileHelpGuidePanel's "How To Play" button) can restart the same live
-- instance instead of creating a second one.
local activeReplay: (() -> ())? = nil

local THEME = {
	Panel = Color3.fromRGB(14, 14, 21),
	Stroke = Color3.fromRGB(60, 54, 82),
	StrokeSoft = Color3.fromRGB(40, 38, 54),
	Text = Color3.fromRGB(245, 243, 252),
	SubText = Color3.fromRGB(185, 180, 205),
	Purple = Color3.fromRGB(172, 120, 255),
	RedDark = Color3.fromRGB(78, 18, 29),
	Button = Color3.fromRGB(38, 34, 52),
	ButtonHover = Color3.fromRGB(53, 48, 72),
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Stroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function tween(instance, duration, props)
	local tw = TweenService:Create(instance, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function tutorialAlreadySeen(stats)
	if typeof(stats) ~= "table" then
		return false
	end

	if stats.BitKaisenFirstTimeGuidanceSeen == true or stats.FirstTimeGuidanceSeen == true then
		return true
	end

	local flags = stats.TutorialFlags
	if typeof(flags) == "table" then
		return flags.BitKaisenFirstTimeGuidanceSeen == true or flags.FirstTimeGuidanceSeen == true
	end

	return false
end

local function init(playerGui: Instance)
	local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent")
	local markTutorialSeen = ReplicatedStorage:FindFirstChild("MarkTutorialSeen")
	local updateSettingsEvent = ReplicatedStorage:FindFirstChild("UpdateSettingsEvent")

	local STEPS = guidanceSteps.buildSteps()

	local state = {
		Stats = nil,
		StepIndex = 0,
		Finished = false,
		Showing = false,
		Started = false,
		MarkedServer = false,
		ManualReplay = false,
		Highlight = nil :: { destroy: () -> () }?,
	}

	local function clearHighlight()
		if state.Highlight then
			state.Highlight.destroy()
			state.Highlight = nil
		end
	end

	local function resolveMainPanel(): Instance?
		local mainGui = playerGui:FindFirstChild(MAIN_GUI_NAME)
		return mainGui and mainGui:FindFirstChild("MainPanel")
	end

	-- Cached proxy frame for TargetIconGroup below: an invisible Frame sized
	-- to the real bounding box of our 7 topbar icons. Parented on a plain
	-- (IgnoreGuiInset = false) layer of our own -- confirmed live in Studio
	-- that a Frame there reports AbsolutePosition exactly equal to whatever
	-- Position we set (no inset math needed), unlike IgnoreGuiInset = true
	-- layers, which subtract the inset. That's the actual root cause the
	-- Quick Access highlight kept failing all session: FocusHighlight's own
	-- overlay (IgnoreGuiInset = true) needs the inset added back to land on
	-- a target's true position, and that fix (see FocusHighlight.luau) is
	-- what makes this proxy resolve correctly now regardless of which layer
	-- it lives in.
	local iconGroupLayer: ScreenGui? = nil
	local iconGroupProxy: Frame? = nil

	local function getIconGroupProxy(): Frame
		if not iconGroupLayer or not iconGroupLayer.Parent then
			local layer = Instance.new("ScreenGui")
			layer.Name = "GuideIconGroupProxyLayer"
			layer.ResetOnSpawn = false
			layer.IgnoreGuiInset = false
			layer.DisplayOrder = 679
			layer.Parent = playerGui
			iconGroupLayer = layer
		end
		if not iconGroupProxy or not iconGroupProxy.Parent then
			local proxy = Instance.new("Frame")
			proxy.Name = "GuideIconGroupProxy"
			proxy.BackgroundTransparency = 1
			proxy.Parent = iconGroupLayer
			iconGroupProxy = proxy
		end
		return iconGroupProxy :: Frame
	end

	-- Roblox's own native menu icon lives inside the same holder as our 7
	-- custom ones, all as "IconSpot" frames -- but the native one sits at a
	-- clearly different Y (confirmed live: ours at y=-42, the native one at
	-- y=-58, far over at x=176, with no overlap between the two groups).
	-- Grouping by Y and taking the LARGEST group keeps the native icon from
	-- dragging the box out to the left edge of the screen.
	local function applyIconGroupBounds(): boolean
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui.Name:find("Topbar") then
				local holders = gui:FindFirstChild("Holders")
				local right = holders and holders:FindFirstChild("Right")
				if right then
					local groups = {}
					for _, d in ipairs(right:GetDescendants()) do
						if d.Name == "IconSpot" and d:IsA("GuiObject") then
							local y = math.floor(d.AbsolutePosition.Y + 0.5)
							groups[y] = groups[y] or {}
							table.insert(groups[y], d)
						end
					end
					local bestGroup = nil
					for _, group in pairs(groups) do
						if not bestGroup or #group > #bestGroup then
							bestGroup = group
						end
					end
					if bestGroup then
						local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
						for _, d in ipairs(bestGroup) do
							local pos = d.AbsolutePosition
							local size = d.AbsoluteSize
							minX = math.min(minX, pos.X)
							minY = math.min(minY, pos.Y)
							maxX = math.max(maxX, pos.X + size.X)
							maxY = math.max(maxY, pos.Y + size.Y)
						end
						local proxy = getIconGroupProxy()
						proxy.Position = UDim2.fromOffset(minX, minY)
						proxy.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
						return true
					end
				end
			end
		end
		return false
	end

	local function resolveIconGroupTarget(): GuiObject?
		if not applyIconGroupBounds() then
			return nil
		end
		task.delay(0.6, applyIconGroupBounds)
		return iconGroupProxy
	end

	local function resolveTarget(step): GuiObject?
		if step.TargetGlobalPath then
			local current: Instance? = playerGui
			for part in string.gmatch(step.TargetGlobalPath, "[^%.]+") do
				current = current and current:FindFirstChild(part)
			end
			return current :: GuiObject?
		end

		if step.TargetIconGroup then
			return resolveIconGroupTarget()
		end

		local mainPanel = resolveMainPanel()
		if not mainPanel then return nil end

		if step.NavId then
			-- Mobile nav buttons are named after the raw navRegistry id (no
			-- "Button" suffix -- see MobileNavPanel in mobileShell.luau),
			-- nested inside a "NavAnchor" scroll rather than a "NavPanel".
			local btn = mainPanel:FindFirstChild(step.NavId, true)
			return btn :: GuiObject?
		end

		if step.TargetPath then
			local mobileName = TARGET_PATH_MAP[step.TargetPath] or step.TargetPath
			local found = mainPanel:FindFirstChild(mobileName, true)
			return found :: GuiObject?
		end

		return nil
	end

	local function isCustomizationOpen()
		local standalone = playerGui:FindFirstChild("BitKaisenMobileCharacterCustomizationGui")
		if standalone and standalone.Enabled ~= false then
			local overlayFrame = standalone:FindFirstChild("CustomizationOverlay", true)
			if overlayFrame and overlayFrame:IsA("GuiObject") and overlayFrame.Visible then
				return true
			end
		end
		return false
	end

	local function markSeen()
		if state.MarkedServer then
			return
		end
		state.MarkedServer = true
		if markTutorialSeen and markTutorialSeen:IsA("RemoteEvent") then
			markTutorialSeen:FireServer("BitKaisenFirstTimeGuidance")
		end
	end

	local guideGui = Instance.new("ScreenGui")
	guideGui.Name = GUI_NAME
	guideGui.ResetOnSpawn = false
	guideGui.IgnoreGuiInset = false
	guideGui.DisplayOrder = 680
	guideGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	guideGui.AutoLocalize = false
	-- Off until we actually decide to show the tutorial -- see the matching
	-- comment in FirstTimeGuidancePanel.luau (PC). Left at the ScreenGui
	-- default (Enabled=true), the full-screen root would block taps from the
	-- instant this module loads until the first UpdateLifeEvent arrives,
	-- which is exactly what froze input on PC when it collided with the
	-- Daily Login modal opening during that window.
	guideGui.Enabled = false
	guideGui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	-- NOT fully transparent (1) on purpose. Mobile nav buttons don't use
	-- Roblox's native click routing -- they go through mobileComponents.
	-- bindTap's own tap router (see mobileComponents.luau's
	-- setupTapRouter), which does its OWN hit-testing via
	-- GetGuiObjectsAtPosition and completely ignores GuiObject.Active. That
	-- router only treats a higher-DisplayOrder object as "blocking" if its
	-- BackgroundTransparency < 1 -- so a fully transparent root (1) is
	-- invisible to it no matter what Active is set to, letting taps fall
	-- through to whatever real nav button happens to sit at that pixel
	-- (confirmed: tapping near NEXT was landing on the real "Trabajos" nav
	-- button). 0.999 is visually identical to fully transparent but still
	-- satisfies that router's "< 1" check across the whole screen.
	root.BackgroundTransparency = 0.999
	root.BackgroundColor3 = Color3.new(0, 0, 0)
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Position = UDim2.fromScale(0, 0)
	root.Active = true
	root.ZIndex = 900
	root.Parent = guideGui

	local card = Instance.new("Frame")
	card.Name = "GuidanceCard"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.BackgroundColor3 = THEME.Panel
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Visible = false
	card.Active = true
	card.ZIndex = 901
	card.Size = UDim2.fromOffset(340, 132)
	card.Position = UDim2.new(0.5, 0, 1, -24)
	card.Parent = root
	addCorner(card, 12)
	addStroke(card, THEME.Stroke, 2, 0.08)
	responsiveScale.attach(card, 340, 132)

	local stepLabel = Instance.new("TextLabel")
	stepLabel.Name = "StepCounter"
	stepLabel.BackgroundTransparency = 1
	stepLabel.BorderSizePixel = 0
	stepLabel.Text = ""
	stepLabel.TextColor3 = THEME.SubText
	stepLabel.TextTransparency = 1
	stepLabel.TextSize = 9
	stepLabel.Font = Enum.Font.Code
	stepLabel.Position = UDim2.new(1, -70, 0, 10)
	stepLabel.Size = UDim2.new(0, 56, 0, 14)
	stepLabel.TextXAlignment = Enum.TextXAlignment.Right
	stepLabel.ZIndex = 903
	stepLabel.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.BackgroundColor3 = THEME.Purple
	accent.BackgroundTransparency = 1
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 5, 1, -18)
	accent.Position = UDim2.new(0, 12, 0, 9)
	accent.ZIndex = 902
	accent.Parent = card
	addCorner(accent, 6)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = ""
	titleLabel.TextColor3 = THEME.Text
	titleLabel.TextTransparency = 1
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Position = UDim2.new(0, 28, 0, 10)
	titleLabel.Size = UDim2.new(1, -100, 0, 20)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.TextWrapped = true
	titleLabel.ZIndex = 903
	titleLabel.Parent = card

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.Name = "Body"
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.BorderSizePixel = 0
	bodyLabel.Text = ""
	bodyLabel.TextColor3 = THEME.SubText
	bodyLabel.TextTransparency = 1
	bodyLabel.TextSize = 12
	bodyLabel.Font = Enum.Font.GothamMedium
	bodyLabel.Position = UDim2.new(0, 28, 0, 34)
	bodyLabel.Size = UDim2.new(1, -44, 0, 52)
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.TextWrapped = true
	bodyLabel.ZIndex = 903
	bodyLabel.Parent = card

	local function makeButton(name, text, color, sizeX, posX)
		local button = Instance.new("TextButton")
		button.Name = name
		button.BackgroundColor3 = color or THEME.Button
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.Text = text or "OK"
		button.TextColor3 = THEME.Text
		button.TextTransparency = 1
		button.TextSize = 13
		button.Font = Enum.Font.GothamBlack
		button.AutoButtonColor = false
		button.Active = true
		button.ZIndex = 904
		button.Size = UDim2.new(0, sizeX, 0, 34)
		button.Position = UDim2.new(posX, 0, 1, -44)
		button.Parent = card
		addCorner(button, 8)
		addStroke(button, THEME.StrokeSoft, 1, 0)
		return button
	end

	local skipButton = makeButton("SkipButton", _g("btn_skip", "SKIP"), THEME.RedDark, 84, 0)
	skipButton.Position = UDim2.new(0, 24, 1, -44)
	local nextButton = makeButton("NextButton", _g("btn_next", "NEXT"), THEME.Purple, 110, 1)
	nextButton.AnchorPoint = Vector2.new(1, 0)
	nextButton.Position = UDim2.new(1, -24, 1, -44)

	-- Opt-in modal shown once, right after the last step, asking whether to
	-- keep the persistent Guide on (see plan "sorted-popping-haven" Fase 2/3).
	local optInGui = Instance.new("ScreenGui")
	optInGui.Name = "BitKaisenMobileGuideOptInUI"
	optInGui.ResetOnSpawn = false
	optInGui.IgnoreGuiInset = false
	optInGui.DisplayOrder = 681
	optInGui.Enabled = false
	optInGui.AutoLocalize = false
	optInGui.Parent = playerGui

	local optInOverlay = Instance.new("Frame")
	optInOverlay.Name = "Overlay"
	optInOverlay.Size = UDim2.fromScale(1, 1)
	optInOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	optInOverlay.BackgroundTransparency = 0.4
	optInOverlay.BorderSizePixel = 0
	optInOverlay.Active = true
	optInOverlay.Parent = optInGui

	-- Styled to match GodModePanel.luau's flat-panel convention (see
	-- HelpGuidePanel.luau's own rewrite for the same reasoning) instead of
	-- the one-off "classified dossier" header/footer bars.
	local GM_BG = Color3.fromRGB(13, 13, 20)
	local GM_STROKE = Color3.fromRGB(116, 84, 165)
	local GM_GOLD = Color3.fromRGB(255, 212, 94)
	local GM_PURPLE = Color3.fromRGB(156, 96, 246)
	local GM_MUTED = Color3.fromRGB(176, 169, 195)

	local optInCard = Instance.new("Frame")
	optInCard.Name = "GuideOptInCard"
	optInCard.AnchorPoint = Vector2.new(0.5, 0.5)
	optInCard.Position = UDim2.fromScale(0.5, 0.5)
	optInCard.Size = UDim2.fromOffset(320, 220)
	optInCard.BackgroundColor3 = GM_BG
	optInCard.BorderSizePixel = 0
	optInCard.Active = true
	optInCard.Parent = optInOverlay
	addCorner(optInCard, 10)
	addStroke(optInCard, GM_STROKE, 1, 0)
	responsiveScale.attach(optInCard, 320, 220)

	local optInTitle = Instance.new("TextLabel")
	optInTitle.BackgroundTransparency = 1
	optInTitle.Position = UDim2.new(0, 18, 0, 16)
	optInTitle.Size = UDim2.new(1, -36, 0, 24)
	optInTitle.Text = _g("optin_title", "Keep the Guide on?")
	optInTitle.TextColor3 = GM_GOLD
	optInTitle.TextSize = 18
	optInTitle.Font = Enum.Font.GothamBlack
	optInTitle.TextXAlignment = Enum.TextXAlignment.Left
	optInTitle.Parent = optInCard

	local optInBody = Instance.new("TextLabel")
	optInBody.BackgroundTransparency = 1
	optInBody.Position = UDim2.new(0, 18, 0, 46)
	optInBody.Size = UDim2.new(1, -36, 0, 66)
	optInBody.Text = _g("optin_body", "The Guide points at a smart next move -- training, a fight, a trip -- so you're never lost. You can change this anytime in Menu > Settings.")
	optInBody.TextColor3 = GM_MUTED
	optInBody.TextSize = 12
	optInBody.Font = Enum.Font.GothamMedium
	optInBody.TextWrapped = true
	optInBody.TextXAlignment = Enum.TextXAlignment.Left
	optInBody.TextYAlignment = Enum.TextYAlignment.Top
	optInBody.Parent = optInCard

	local keepButton = Instance.new("TextButton")
	keepButton.Name = "KeepGuideButton"
	keepButton.Position = UDim2.new(0, 18, 0, 120)
	keepButton.Size = UDim2.new(1, -36, 0, 42)
	keepButton.BackgroundColor3 = GM_PURPLE
	keepButton.Text = _g("optin_keep_button", "KEEP GUIDE ON")
	keepButton.TextColor3 = THEME.Text
	keepButton.TextSize = 14
	keepButton.Font = Enum.Font.GothamBlack
	keepButton.AutoButtonColor = true
	keepButton.Parent = optInCard
	addCorner(keepButton, 8)

	local skipGuideButton = Instance.new("TextButton")
	skipGuideButton.Name = "SkipGuideButton"
	skipGuideButton.BackgroundTransparency = 1
	skipGuideButton.Position = UDim2.new(0, 18, 0, 172)
	skipGuideButton.Size = UDim2.new(1, -36, 0, 20)
	skipGuideButton.Text = _g("optin_skip_button", "No thanks, turn it off")
	skipGuideButton.TextColor3 = GM_MUTED
	skipGuideButton.TextSize = 12
	skipGuideButton.Font = Enum.Font.GothamMedium
	skipGuideButton.AutoButtonColor = false
	skipGuideButton.Parent = optInCard

	local function closeOptIn()
		optInGui.Enabled = false
	end

	local function showOptIn()
		optInGui.Enabled = true
	end

	keepButton.MouseButton1Click:Connect(function()
		if updateSettingsEvent then
			updateSettingsEvent:FireServer("GuideEnabled", true)
		end
		closeOptIn()
	end)

	skipGuideButton.MouseButton1Click:Connect(function()
		if updateSettingsEvent then
			updateSettingsEvent:FireServer("GuideEnabled", false)
		end
		closeOptIn()
	end)

	-- Card sits bottom-anchored by default, but if the current target's own
	-- bounds are ALSO in the bottom half of the screen (e.g. LogContainer),
	-- a fixed bottom card would sit right on top of it -- so flip the card
	-- to the top half instead whenever the target is in the bottom half.
	local function positionCardForTarget(target: GuiObject?, step)
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

		-- "right" only makes sense with an actual second column of free
		-- space (PC's wide layout). Mobile is a single narrow column, so
		-- pinning to the right edge there just spans nearly the whole
		-- screen and overlaps whatever's already there (confirmed). Falls
		-- through to the normal top/bottom auto-flip below instead.
		if step and step.CardSide == "right" and viewport.X >= 700 then
			card.AnchorPoint = Vector2.new(1, 0.5)
			card.Position = UDim2.new(1, -12, 0.5, 0)
			return
		end

		local useTop = false
		if target then
			local pos = target.AbsolutePosition
			local size = target.AbsoluteSize
			local centerY = pos.Y + size.Y / 2
			useTop = centerY > viewport.Y * 0.5
		end
		if useTop then
			card.AnchorPoint = Vector2.new(0.5, 0)
			card.Position = UDim2.new(0.5, 0, 0, 24)
		else
			card.AnchorPoint = Vector2.new(0.5, 1)
			card.Position = UDim2.new(0.5, 0, 1, -24)
		end
	end

	local function setStep(index)
		local step = STEPS[index]
		if not step then
			state.Finished = true
			state.Showing = false
			state.ManualReplay = false
			markSeen()
			clearHighlight()

			tween(card, 0.12, { BackgroundTransparency = 1 })
			tween(accent, 0.1, { BackgroundTransparency = 1 })
			tween(titleLabel, 0.1, { TextTransparency = 1 })
			tween(bodyLabel, 0.1, { TextTransparency = 1 })
			tween(stepLabel, 0.1, { TextTransparency = 1 })
			tween(skipButton, 0.1, { BackgroundTransparency = 1, TextTransparency = 1 })
			tween(nextButton, 0.1, { BackgroundTransparency = 1, TextTransparency = 1 })

			task.delay(0.15, function()
				card.Visible = false
				guideGui.Enabled = false
				showOptIn()
			end)

			return
		end

		state.StepIndex = index
		state.Showing = true

		titleLabel.Text = step.Title
		bodyLabel.Text = step.Body
		stepLabel.Text = string.format("%d/%d", index, #STEPS)
		nextButton.Text = step.Button or _g("btn_next", "NEXT")

		clearHighlight()
		local target = resolveTarget(step)
		positionCardForTarget(target, step)
		if target then
			state.Highlight = FocusHighlight.attach(target, {
				color = THEME.Purple,
				corner = 8,
				label = step.Title,
				dimBackground = true,
			})
		end

		card.Visible = true
		card.BackgroundTransparency = 1
		accent.BackgroundTransparency = 1
		titleLabel.TextTransparency = 1
		bodyLabel.TextTransparency = 1
		stepLabel.TextTransparency = 1
		skipButton.BackgroundTransparency = 1
		skipButton.TextTransparency = 1
		nextButton.BackgroundTransparency = 1
		nextButton.TextTransparency = 1

		tween(card, 0.16, { BackgroundTransparency = 0 })
		tween(accent, 0.12, { BackgroundTransparency = 0 })
		tween(titleLabel, 0.12, { TextTransparency = 0 })
		tween(bodyLabel, 0.12, { TextTransparency = 0 })
		tween(stepLabel, 0.12, { TextTransparency = 0.3 })
		tween(skipButton, 0.12, { BackgroundTransparency = 0, TextTransparency = 0 })
		tween(nextButton, 0.12, { BackgroundTransparency = 0, TextTransparency = 0 })
	end

	local startTutorial
	startTutorial = function()
		if state.Finished or state.Started then
			return
		end

		state.Started = true

		task.spawn(function()
			local startedAt = os.clock()

			while os.clock() - startedAt < 8 do
				if state.Finished then
					return
				end
				if not isCustomizationOpen() then
					break
				end
				task.wait(0.25)
			end

			if state.Finished or isCustomizationOpen() then
				state.Started = false
				task.delay(2, startTutorial)
				return
			end

			guideGui.Enabled = true
			setStep(1)
		end)
	end

	local function replayTutorial()
		closeOptIn()
		clearHighlight()
		state.ManualReplay = true
		state.Finished = false
		state.Started = true
		guideGui.Enabled = true
		setStep(1)
	end

	skipButton.MouseButton1Click:Connect(function()
		state.Finished = true
		markSeen()
		clearHighlight()
		setStep(#STEPS + 1)
	end)

	nextButton.MouseButton1Click:Connect(function()
		setStep(state.StepIndex + 1)
	end)

	updateLifeEvent.OnClientEvent:Connect(function(stats)
		state.Stats = stats

		if typeof(stats) ~= "table" then
			return
		end

		if stats.Alive == false then
			card.Visible = false
			state.Showing = false
			clearHighlight()
			return
		end

		if tutorialAlreadySeen(stats) and not state.ManualReplay then
			state.Finished = true
			state.MarkedServer = true
			card.Visible = false
			guideGui.Enabled = false
			clearHighlight()
			return
		end

		if not state.Started and not state.Finished then
			task.delay(0.9, function()
				if state.Stats and state.Stats.Alive ~= false and not state.Finished then
					startTutorial()
				end
			end)
		end
	end)

	activeReplay = replayTutorial
end

local function replay()
	if activeReplay then
		activeReplay()
	end
end

return { init = init, replay = replay }
