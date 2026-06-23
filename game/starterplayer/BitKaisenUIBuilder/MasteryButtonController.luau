-- ModuleScript: MasteryButtonController
-- Location: StarterPlayerScripts.BitKaisenUIBuilder.MasteryButtonController
-- Purpose:
--   Pins the Technique/Mastery "?" button in a stable spot beside the Technique row.
--
-- Why this version exists:
--   Previous versions measured the Technique text width.
--   That made the button move when aging/profile refreshes reapplied text.
--
-- Fix:
--   Use a fixed X slot.
--   No text-width measuring.
--   No RenderStepped loop.
--   No ParentChanged/PositionChanged fighting.
--   Never adopts TraitDetailsOpenButton.

local MasteryButtonController = {}

function MasteryButtonController.Init(gui, techRow, techLabel, ageUpButton, RunService, TextService)
	local adoptedButton = nil
	local descAddedConnection = nil
	local descRemovingConnection = nil
	local rowSizeConnection = nil

	local BUTTON_SIZE = 18
	local BUTTON_FIXED_X = 155
	local BUTTON_RIGHT_PADDING = 2
	local LABEL_GAP = 7

	local REAL_MASTERY_BUTTON_NAMES = {
		TechniqueInfoButton = true,
		TechniqueQuestionButton = true,
		MasteryQuestionButton = true,
		TechniqueMasteryButton = true,
		TechniqueDetailsOpenButton = true,
		MasteryDetailsOpenButton = true,
		MasteryOpenButton = true,
	}

	local function looksLikeMasteryButton(instance)
		if not instance or not instance:IsA("TextButton") then
			return false
		end

		if instance == ageUpButton then
			return false
		end

		if instance.Name == "TraitDetailsOpenButton" then
			return false
		end

		if REAL_MASTERY_BUTTON_NAMES[instance.Name] then
			return true
		end

		local lowerName = string.lower(tostring(instance.Name or ""))
		local lowerParentName = instance.Parent and string.lower(tostring(instance.Parent.Name or "")) or ""

		if instance.Text == "?" then
			if string.find(lowerName, "technique")
				or string.find(lowerName, "mastery")
				or string.find(lowerParentName, "technique")
				or string.find(lowerParentName, "mastery") then
				return true
			end
		end

		return false
	end

	local function getPinnedX()
		local rowWidth = techRow.AbsoluteSize.X

		if rowWidth <= 0 then
			return BUTTON_FIXED_X
		end

		local maxX = math.max(0, rowWidth - BUTTON_SIZE - BUTTON_RIGHT_PADDING)
		return math.clamp(BUTTON_FIXED_X, 0, maxX)
	end

	local function layoutButton()
		if not adoptedButton or not adoptedButton.Parent then
			return
		end

		if not techRow or not techRow.Parent then
			return
		end

		if not techLabel or not techLabel.Parent then
			return
		end

		local pinnedX = getPinnedX()

		if adoptedButton.Parent ~= techRow then
			adoptedButton.Parent = techRow
		end

		techRow.ClipsDescendants = false

		techLabel.Position = UDim2.new(0, 0, 0, 0)
		techLabel.Size = UDim2.new(0, math.max(30, pinnedX - LABEL_GAP), 1, 0)
		techLabel.TextWrapped = false
		techLabel.TextTruncate = Enum.TextTruncate.AtEnd
		techLabel.TextXAlignment = Enum.TextXAlignment.Left
		techLabel.TextYAlignment = Enum.TextYAlignment.Center

		adoptedButton.AnchorPoint = Vector2.new(0, 0.5)
		adoptedButton.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		adoptedButton.Position = UDim2.new(0, pinnedX, 0.5, 0)
		adoptedButton.Visible = true
		adoptedButton.Active = true
		adoptedButton.Text = "?"
		adoptedButton.TextScaled = false
		adoptedButton.TextSize = 12
		adoptedButton.Font = Enum.Font.GothamBlack
		adoptedButton.ZIndex = math.max(adoptedButton.ZIndex or 1, 20)
	end

	local scheduled = false

	local function scheduleLayout()
		if scheduled then
			return
		end

		scheduled = true

		task.defer(function()
			scheduled = false
			layoutButton()
		end)
	end

	local function adoptButton(button)
		if not button then
			return
		end

		if button == ageUpButton then
			return
		end

		if button.Name == "TraitDetailsOpenButton" then
			return
		end

		adoptedButton = button
		layoutButton()

		if not rowSizeConnection then
			rowSizeConnection = techRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(scheduleLayout)
		end

		task.delay(0.05, layoutButton)
		task.delay(0.25, layoutButton)
		task.delay(0.75, layoutButton)
	end

	local function findExistingButton()
		for _, descendant in ipairs(gui:GetDescendants()) do
			if looksLikeMasteryButton(descendant) then
				return descendant
			end
		end

		return nil
	end

	local function tryAdoptExisting()
		local existing = findExistingButton()
		if existing then
			adoptButton(existing)
		end
	end

	tryAdoptExisting()

	descAddedConnection = gui.DescendantAdded:Connect(function(descendant)
		if adoptedButton and adoptedButton.Parent then
			return
		end

		if looksLikeMasteryButton(descendant) then
			task.defer(function()
				if descendant and descendant.Parent then
					adoptButton(descendant)
				end
			end)
		end
	end)

	descRemovingConnection = gui.DescendantRemoving:Connect(function(descendant)
		if descendant == adoptedButton then
			adoptedButton = nil
			task.defer(tryAdoptExisting)
		end
	end)

	task.defer(layoutButton)
	task.delay(0.1, layoutButton)
	task.delay(0.5, layoutButton)
end

return MasteryButtonController
