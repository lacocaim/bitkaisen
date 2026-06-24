-- ModuleScript: TraitButtonController
-- Location: StarterPlayerScripts.BitKaisenUIBuilder.TraitButtonController
-- Purpose:
--   Places the real TraitDetailsOpenButton beside the Traits row.
--   This module ONLY adopts TraitDetailsOpenButton and never touches mastery buttons.
--
-- Fix:
--   No ParentChanged / PositionChanged lock loops.
--   No RenderStepped loop.
--   Reflows only when row size or text changes.

local TraitButtonController = {}

local function stripRichText(text)
	text = tostring(text or "")
	text = text:gsub("<br%s*/>", "\n")
	text = text:gsub("<[^>]->", "")
	text = text:gsub("&lt;", "<")
	text = text:gsub("&gt;", ">")
	text = text:gsub("&amp;", "&")
	text = text:gsub("&quot;", "\"")
	text = text:gsub("&apos;", "'")
	return text
end

function TraitButtonController.Init(gui, traitRow, traitLabel, RunService)
	local TextService = game:GetService("TextService")

	local adoptedButton = nil
	local reflowQueued = false

	local BUTTON_SIZE = 18
	local BUTTON_GAP = 6
	local RIGHT_PADDING = 2

	local function looksLikeRealTraitButton(instance)
		return instance
			and instance:IsA("TextButton")
			and instance.Name == "TraitDetailsOpenButton"
	end

	local function measureTraitTextWidth()
		if not traitRow or not traitRow.Parent or not traitLabel or not traitLabel.Parent then
			return 0
		end

		local rowWidth = traitRow.AbsoluteSize.X
		if rowWidth <= 0 then
			return 0
		end

		local plainText = stripRichText(traitLabel.Text)
		if plainText == "" then
			return 0
		end

		local bounds = Vector2.new(math.max(1, rowWidth), math.max(1, traitRow.AbsoluteSize.Y))
		local ok, measured = pcall(function()
			return TextService:GetTextSize(plainText, traitLabel.TextSize, traitLabel.Font, bounds)
		end)

		if ok and measured then
			return measured.X
		end

		return math.min(rowWidth, #plainText * math.max(6, traitLabel.TextSize * 0.55))
	end

	local function getWantedX()
		if not traitRow or not traitRow.Parent then
			return 145
		end

		local rowWidth = traitRow.AbsoluteSize.X
		if rowWidth <= 0 then
			return 145
		end

		local maxX = math.max(0, rowWidth - BUTTON_SIZE - RIGHT_PADDING)
		local textWidth = measureTraitTextWidth()
		return math.clamp(textWidth + BUTTON_GAP, 0, maxX)
	end

	local function forceLayout()
		if not adoptedButton or not adoptedButton.Parent then
			return
		end

		if not traitRow or not traitRow.Parent or not traitLabel or not traitLabel.Parent then
			return
		end

		if adoptedButton.Parent ~= traitRow then
			adoptedButton.Parent = traitRow
		end

		traitRow.ClipsDescendants = false
		traitLabel.Position = UDim2.new(0, 0, 0, 0)
		traitLabel.Size = UDim2.new(1, -(BUTTON_SIZE + BUTTON_GAP + RIGHT_PADDING), 1, 0)
		traitLabel.TextWrapped = false
		traitLabel.TextTruncate = Enum.TextTruncate.AtEnd
		traitLabel.TextXAlignment = Enum.TextXAlignment.Left
		traitLabel.TextYAlignment = Enum.TextYAlignment.Center

		adoptedButton.AnchorPoint = Vector2.new(0, 0.5)
		adoptedButton.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		adoptedButton.Position = UDim2.new(0, getWantedX(), 0.5, 0)
		adoptedButton.Visible = true
		adoptedButton.Active = true
		adoptedButton.Text = "?"
		adoptedButton.TextScaled = false
		adoptedButton.TextSize = 12
		adoptedButton.Font = Enum.Font.GothamBlack
		adoptedButton.ZIndex = math.max(adoptedButton.ZIndex or 1, 20)
	end

	local function queueReflow()
		if reflowQueued then
			return
		end

		reflowQueued = true
		task.delay(0.03, function()
			reflowQueued = false
			forceLayout()
		end)
	end

	local function adopt(button)
		if not looksLikeRealTraitButton(button) then
			return false
		end

		adoptedButton = button
		forceLayout()
		return true
	end

	local function findExisting()
		for _, descendant in ipairs(gui:GetDescendants()) do
			if looksLikeRealTraitButton(descendant) then
				return descendant
			end
		end
		return nil
	end

	local function tryAdoptExisting()
		if adoptedButton and adoptedButton.Parent then
			return true
		end

		local existing = findExisting()
		if existing then
			return adopt(existing)
		end

		return false
	end

	tryAdoptExisting()

	gui.DescendantAdded:Connect(function(descendant)
		if adoptedButton and adoptedButton.Parent then
			return
		end

		if looksLikeRealTraitButton(descendant) then
			task.delay(0.03, function()
				if descendant and descendant.Parent then
					adopt(descendant)
				end
			end)
		end
	end)

	gui.DescendantRemoving:Connect(function(descendant)
		if descendant == adoptedButton then
			adoptedButton = nil
			task.delay(0.05, tryAdoptExisting)
		end
	end)

	traitRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueReflow)
	traitLabel:GetPropertyChangedSignal("Text"):Connect(queueReflow)
	traitLabel:GetPropertyChangedSignal("TextSize"):Connect(queueReflow)

	task.delay(0.05, queueReflow)
	task.delay(0.35, queueReflow)
end

return TraitButtonController

