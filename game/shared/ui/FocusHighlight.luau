-- Shared spotlight component used by both the onboarding tutorial and the
-- persistent Guide (see project-bitkaisen-tutorial-system memory / plan
-- "sorted-popping-haven"): a pulsing border + a bobbing arrow pointing at
-- whatever GuiObject needs the player's attention.
--
-- Drawn on a dedicated top-level overlay layer (NOT parented inside the
-- target) so the border sits visibly outside the target's own edges and can
-- render over other UI (ScrollingFrame clipping, other panels, etc.) instead
-- of being cut off by the target's own ClipsDescendants -- see BitSeas
-- reference where the callout always floats above/over everything.
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local theme = require("@ui/theme")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LAYER_NAME = "FocusHighlightLayer"
local LOW_LAYER_NAME = "FocusHighlightLayerLow"
local DIM_LAYER_NAME = "FocusDimLayer"
local DIM_TRANSPARENCY = 0.55

local PULSE_TIME = 0.9
local PULSE_MIN_TRANSPARENCY = 0
local PULSE_MAX_TRANSPARENCY = 0.75
local ARROW_BOB_TIME = 0.6
local ARROW_BOB_DISTANCE = 8

-- How far outside the target's own edges the border sits.
local OUTWARD_PAD = 6

local ARROW_GAP = 4
local ARROW_WIDTH = 20
local ARROW_HEIGHT = 16
local LABEL_GAP = 2
local LABEL_HEIGHT = 20

export type FocusHighlightHandle = {
	destroy: () -> (),
}

export type FocusHighlightOptions = {
	color: Color3?,
	corner: number?,
	thickness: number?,
	arrow: boolean?,
	label: string?,
	dimBackground: boolean?,
	belowPanels: boolean?,
}

-- Default layer (1500) sits above literally everything -- needed by the
-- tutorial, which deliberately wants its spotlight visible over its own
-- dim/card UI. The persistent Guide (opts.belowPanels = true) uses a
-- SEPARATE, much lower layer (16 -- just above the dashboard's own 15,
-- comfortably below every real panel's DisplayOrder, all of which sit in
-- the 618-730 range) instead. That way it's naturally hidden behind
-- whatever the player has open -- panels, modals, overlays, one-off things
-- like the Daily Login popup -- without having to specifically track each
-- of those separate "is something open" mechanisms (tried that: routes,
-- modals, and overlays are all different systems in this codebase, and kept
-- missing new cases -- z-order fixes the whole category at once).
local function getLayer(low: boolean?): ScreenGui
	local name = low and LOW_LAYER_NAME or LAYER_NAME
	local layer = playerGui:FindFirstChild(name)
	if layer then return layer :: ScreenGui end

	layer = Instance.new("ScreenGui")
	layer.Name = name
	layer.ResetOnSpawn = false
	layer.IgnoreGuiInset = true
	layer.DisplayOrder = low and 16 or 1500
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer.Parent = playerGui
	return layer :: ScreenGui
end

-- Separate, lower layer for the optional "spotlight" dim (opts.dimBackground):
-- it needs to sit ABOVE the normal dashboard (DisplayOrder 15) so it actually
-- darkens it, but BELOW any explanation card the caller shows (e.g.
-- FirstTimeGuidancePanel's guideGui at 680) so that card stays fully visible
-- -- only FocusHighlightLayer itself (1500, the border/arrow/label) should
-- render above the dim. Four rects (top/bottom/left/right of the target)
-- leave a real rectangular gap instead of just being transparent there, so
-- the target shows through at full brightness -- not a transparency trick.
local function getDimLayer(): ScreenGui
	local layer = playerGui:FindFirstChild(DIM_LAYER_NAME)
	if layer then return layer :: ScreenGui end

	layer = Instance.new("ScreenGui")
	layer.Name = DIM_LAYER_NAME
	layer.ResetOnSpawn = false
	layer.IgnoreGuiInset = true
	layer.DisplayOrder = 650
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer.Parent = playerGui
	return layer :: ScreenGui
end

local function makeChevron(parent: Instance, color: Color3, zIndex: number)
	local container = Instance.new("Frame")
	container.Name = "FocusArrow"
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(ARROW_WIDTH, ARROW_HEIGHT)
	container.ZIndex = zIndex
	container.Parent = parent

	local function bar(anchorXScale: number, rotation: number): Frame
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(anchorXScale, 0, 0.5, 0)
		b.Size = UDim2.fromOffset(12, 3)
		b.Rotation = rotation
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.ZIndex = zIndex
		b.Parent = container
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = b
		return b
	end

	bar(0.28, 45)
	bar(0.72, -45)

	return container
end

-- Our own overlay layer (root/dim rects) always lives in a ScreenGui with
-- IgnoreGuiInset = true. Verified empirically in Studio (two throwaway
-- ScreenGuis, same Position set on a child of each): a Frame in an
-- IgnoreGuiInset=true ScreenGui reports AbsolutePosition = Position - inset,
-- while IgnoreGuiInset=false reports AbsolutePosition = Position unchanged.
-- So to make OUR OWN root/dim Frames land on a target's true AbsolutePosition
-- (whatever that target's own AbsolutePosition value is -- that's already
-- final/correct regardless of the target's own ScreenGui setting), we always
-- need to ADD the inset back before assigning our Position -- this is a
-- correction for OUR layer's coordinate system, not the target's, so it does
-- NOT depend on the target's own ScreenGui.IgnoreGuiInset at all. The
-- previous version conditioned this on the target's IgnoreGuiInset, which
-- happened to match for BitKaisenGui/MobileGui dashboard targets (false ->
-- added inset, which is what's always needed) but was wrong for topbar
-- targets living in TopbarStandard (IgnoreGuiInset=true -> returned zero,
-- silently skipping a needed +58px correction and leaving the Quick Access
-- highlight ~58px away from the real icons for the whole session).
local function getInsetOffset(): Vector2
	return GuiService:GetGuiInset()
end

local function attach(target: GuiObject, opts: FocusHighlightOptions?): FocusHighlightHandle
	opts = opts or {}
	local color = opts.color or theme.Gold
	local showArrow = if opts.arrow == nil then true else opts.arrow
	local cornerRadius = (opts.corner or 0) + OUTWARD_PAD

	local layer = getLayer(opts.belowPanels)

	local root = Instance.new("Frame")
	root.Name = "FocusHighlight"
	root.BackgroundTransparency = 1
	root.ZIndex = 1500
	root.Parent = layer

	-- If the target lives inside a ScrollingFrame that's shorter than its
	-- content (e.g. Mobile's dossier profile card, taller than the screen
	-- budget it's given), two things need handling: (1) scroll it so the
	-- target is actually visible instead of wherever it happened to be
	-- scrolled to, and (2) clip our own border to that ScrollingFrame's
	-- visible viewport -- our border renders on a top-level overlay layer
	-- specifically so it ISN'T cut off by ClipsDescendants (needed so it can
	-- render over other panels), but that same trait means it would
	-- otherwise draw past the ScrollingFrame's real bottom edge and bleed
	-- into whatever sits below it on screen (confirmed: the profile card's
	-- border was spilling into the life log below it on Mobile).
	local scrollAncestor: ScrollingFrame? = nil
	do
		local current: Instance? = target.Parent
		while current do
			if current:IsA("ScrollingFrame") then
				scrollAncestor = current :: ScrollingFrame
				break
			end
			current = current.Parent
		end
	end

	if scrollAncestor then
		local sa = scrollAncestor :: ScrollingFrame
		local targetTopInCanvas = (target.AbsolutePosition.Y - sa.AbsolutePosition.Y) + sa.CanvasPosition.Y
		sa.CanvasPosition = Vector2.new(sa.CanvasPosition.X, math.max(0, targetTopInCanvas))
	end

	local dimTop, dimBottom, dimLeft, dimRight = nil, nil, nil, nil
	if opts.dimBackground then
		local dimLayer = getDimLayer()
		local function makeDim(): Frame
			local f = Instance.new("Frame")
			f.Name = "Dim"
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BackgroundTransparency = DIM_TRANSPARENCY
			f.BorderSizePixel = 0
			-- Frames don't block clicks/taps by default in Roblox -- without
			-- this, a tap meant for the tutorial card that lands on the
			-- dimmed area instead (not the small card itself) falls through
			-- to whatever real game button happens to be underneath (this
			-- is exactly what broke Mobile's +AGE step: pressing "next" also
			-- registered on a Jobs button hidden behind the dim).
			f.Active = true
			f.Parent = dimLayer
			return f
		end
		dimTop, dimBottom, dimLeft, dimRight = makeDim(), makeDim(), makeDim(), makeDim()
	end

	local layoutCallout -- forward declare; defined below, called from updateBounds too

	local function updateDim(pos: Vector2, size: Vector2)
		if not dimTop then return end
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local holeRight = pos.X + size.X
		local holeBottom = pos.Y + size.Y

		dimTop.Position = UDim2.fromOffset(0, 0)
		dimTop.Size = UDim2.fromOffset(viewport.X, math.max(0, pos.Y))

		dimBottom.Position = UDim2.fromOffset(0, holeBottom)
		dimBottom.Size = UDim2.fromOffset(viewport.X, math.max(0, viewport.Y - holeBottom))

		dimLeft.Position = UDim2.fromOffset(0, pos.Y)
		dimLeft.Size = UDim2.fromOffset(math.max(0, pos.X), size.Y)

		dimRight.Position = UDim2.fromOffset(holeRight, pos.Y)
		dimRight.Size = UDim2.fromOffset(math.max(0, viewport.X - holeRight), size.Y)
	end

	local function updateBounds()
		if not target.Parent then return end
		local pos = target.AbsolutePosition
		local size = target.AbsoluteSize
		local inset = getInsetOffset()
		local holePos = Vector2.new(pos.X + inset.X - OUTWARD_PAD, pos.Y + inset.Y - OUTWARD_PAD)
		local holeSize = Vector2.new(size.X + OUTWARD_PAD * 2, size.Y + OUTWARD_PAD * 2)

		if scrollAncestor and scrollAncestor.Parent then
			local sa = scrollAncestor :: ScrollingFrame
			local sPos = sa.AbsolutePosition
			local sSize = sa.AbsoluteSize
			local sInset = getInsetOffset()
			local sMinX, sMinY = sPos.X + sInset.X, sPos.Y + sInset.Y
			local sMaxX, sMaxY = sMinX + sSize.X, sMinY + sSize.Y
			local holeRight = math.min(holePos.X + holeSize.X, sMaxX)
			local holeBottom = math.min(holePos.Y + holeSize.Y, sMaxY)
			holePos = Vector2.new(math.max(holePos.X, sMinX), math.max(holePos.Y, sMinY))
			holeSize = Vector2.new(math.max(0, holeRight - holePos.X), math.max(0, holeBottom - holePos.Y))
		end

		root.Position = UDim2.fromOffset(holePos.X, holePos.Y)
		root.Size = UDim2.fromOffset(holeSize.X, holeSize.Y)
		updateDim(holePos, holeSize)
		if layoutCallout then layoutCallout() end
	end
	updateBounds()

	local stroke = Instance.new("UIStroke")
	stroke.Name = "PulseStroke"
	stroke.Color = color
	stroke.Thickness = opts.thickness or 2
	stroke.Transparency = PULSE_MIN_TRANSPARENCY
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = root

	local pulseTween = TweenService:Create(
		stroke,
		TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = PULSE_MAX_TRANSPARENCY }
	)
	pulseTween:Play()

	local arrow = nil
	local labelChip = nil
	local arrowTween = nil
	local belowMode = nil -- nil = not laid out yet

	-- Space needed above the target for the arrow (+ label, if any) to fit
	-- without spilling past the top of the screen / under the native Roblox
	-- topbar. If there isn't enough room, the callout flips to sit BELOW the
	-- target instead (arrow pointing up) rather than clipping off-screen.
	local function neededSpaceAbove()
		local space = ARROW_GAP + ARROW_HEIGHT
		if opts.label then
			space += LABEL_GAP + LABEL_HEIGHT
		end
		return space + 12
	end

	layoutCallout = function()
		if not showArrow then return end

		local wantBelow = root.AbsolutePosition.Y < neededSpaceAbove()
		if belowMode == wantBelow then return end
		belowMode = wantBelow

		if arrowTween then arrowTween:Cancel() end

		local arrowRestY, arrowBobY, labelY, edgeAnchor
		if belowMode then
			edgeAnchor = Vector2.new(0.5, 0)
			arrowRestY = root.AbsoluteSize.Y + ARROW_GAP
			arrowBobY = arrowRestY + ARROW_BOB_DISTANCE
			labelY = arrowRestY + ARROW_HEIGHT + LABEL_GAP
		else
			edgeAnchor = Vector2.new(0.5, 1)
			arrowRestY = -ARROW_GAP - ARROW_HEIGHT
			arrowBobY = arrowRestY - ARROW_BOB_DISTANCE
			labelY = arrowRestY - LABEL_GAP - LABEL_HEIGHT
		end

		if not arrow then
			arrow = makeChevron(root, color, root.ZIndex + 1)
		end
		arrow.AnchorPoint = edgeAnchor
		arrow.Position = UDim2.new(0.5, 0, 0, arrowRestY)
		arrow.Rotation = belowMode and 180 or 0

		arrowTween = TweenService:Create(
			arrow,
			TweenInfo.new(ARROW_BOB_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = UDim2.new(0.5, 0, 0, arrowBobY) }
		)
		arrowTween:Play()

		if opts.label then
			if not labelChip then
				local chipFrame = Instance.new("Frame")
				chipFrame.Name = "FocusLabel"
				chipFrame.Size = UDim2.new(0, 150, 0, LABEL_HEIGHT)
				chipFrame.BackgroundColor3 = theme.Panel or Color3.fromRGB(15, 15, 22)
				chipFrame.BackgroundTransparency = 0.05
				chipFrame.BorderSizePixel = 0
				chipFrame.ZIndex = root.ZIndex + 1
				chipFrame.Parent = root

				local chipCorner = Instance.new("UICorner")
				chipCorner.CornerRadius = UDim.new(0, 6)
				chipCorner.Parent = chipFrame

				local chipStroke = Instance.new("UIStroke")
				chipStroke.Color = color
				chipStroke.Thickness = 1
				chipStroke.Transparency = 0.3
				chipStroke.Parent = chipFrame

				local textLabel = Instance.new("TextLabel")
				textLabel.Name = "Text"
				textLabel.Size = UDim2.fromScale(1, 1)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = string.upper(opts.label)
				textLabel.TextColor3 = color
				textLabel.TextSize = 11
				textLabel.Font = Enum.Font.GothamBlack
				textLabel.ZIndex = chipFrame.ZIndex + 1
				textLabel.Parent = chipFrame

				labelChip = chipFrame
			end
			labelChip.AnchorPoint = edgeAnchor
			labelChip.Position = UDim2.new(0.5, 0, 0, labelY)
		end
	end
	layoutCallout()

	local destroyed = false
	local destroy

	local posConn = target:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBounds)
	local sizeConn = target:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBounds)
	local ancestryConn = target.AncestryChanged:Connect(function(_, parent)
		if parent == nil and not destroyed then
			destroy()
		end
	end)

	destroy = function()
		if destroyed then return end
		destroyed = true
		posConn:Disconnect()
		sizeConn:Disconnect()
		ancestryConn:Disconnect()
		pulseTween:Cancel()
		if arrowTween then arrowTween:Cancel() end
		if root.Parent then root:Destroy() end
		if dimTop then dimTop:Destroy() end
		if dimBottom then dimBottom:Destroy() end
		if dimLeft then dimLeft:Destroy() end
		if dimRight then dimRight:Destroy() end
	end

	return { destroy = destroy }
end

return { attach = attach }
