local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mc = require("@ui/mobile/mobileComponents")
local t = mc.theme

local popupQueue = {}
local isShowing = false
local overlayRef: Frame? = nil
local windowRef: Frame? = nil
local guiRef: ScreenGui? = nil

local function closeCurrentPopup()
	if not isShowing then return end
	if windowRef then
		local closeTween = TweenService:Create(windowRef, TweenInfo.new(0.2), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.55, 0),
		})
		if overlayRef then
			TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		end
		closeTween:Play()
		closeTween.Completed:Wait()
		if overlayRef then overlayRef.Visible = false end
	end
	isShowing = false
	showNextPopup()
end

local titleLabel: TextLabel? = nil
local bodyLabel: TextLabel? = nil
local highlightLabel: TextLabel? = nil
local highlightFrame: Frame? = nil
local footerLabel: TextLabel? = nil
local continueBtn: TextButton? = nil
local accentStroke: UIStroke? = nil

function showNextPopup()
	if #popupQueue == 0 then
		isShowing = false
		if overlayRef then
			TweenService:Create(overlayRef, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.delay(0.2, function() if overlayRef then overlayRef.Visible = false end end)
		end
		return
	end

	local data = table.remove(popupQueue, 1)
	if titleLabel then titleLabel.Text = tostring(data.Title or "EVENT") end
	if bodyLabel then bodyLabel.Text = tostring(data.Body or "") end
	if highlightLabel then highlightLabel.Text = tostring(data.Highlight or "") end

	local footer = tostring(data.Footer or "")
	if footerLabel then
		footerLabel.Text = footer
		footerLabel.Visible = footer ~= ""
	end

	local tone = string.lower(tostring(data.Tone or ""))
	local accent = t.Purple
	local accentBg = t.Panel
	if tone == "success" then
		accent = t.Green
		accentBg = Color3.fromRGB(20, 70, 42)
	elseif tone == "danger" or tone == "error" then
		accent = t.Bad
		accentBg = Color3.fromRGB(92, 24, 34)
	end

	if highlightFrame then highlightFrame.BackgroundColor3 = accentBg end
	if highlightLabel then highlightLabel.TextColor3 = accent end
	if continueBtn then continueBtn.BackgroundColor3 = accent end
	if accentStroke then accentStroke.Color = accent end

	isShowing = true
	if overlayRef then
		overlayRef.Visible = true
		TweenService:Create(overlayRef, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	end
	if windowRef then
		windowRef.BackgroundTransparency = 1
		windowRef.Position = UDim2.new(0.5, 0, 0.55, 0)
		windowRef.Visible = true
		TweenService:Create(windowRef, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	end
end

local function init(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MobilePopupLayer"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	guiRef = gui

	local overlay = Instance.new("Frame")
	overlay.Name = "PopupOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 100
	overlay.Visible = false
	overlay.Active = true
	overlay.Parent = gui
	overlayRef = overlay

	local window = Instance.new("Frame")
	window.Name = "PopupWindow"
	window.Size = UDim2.new(0.92, 0, 0, 340)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.new(0.5, 0, 0.55, 0)
	window.BackgroundColor3 = t.Panel
	window.BorderSizePixel = 0
	window.ZIndex = 101
	window.Visible = false
	window.Parent = overlay
	mc.corner(window, 14)
	accentStroke = mc.stroke(window, t.Bad)
	windowRef = window

	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 34)
	titleLabel.Position = UDim2.new(0, 20, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = t.Text
	titleLabel.TextSize = 22
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = ""
	titleLabel.TextWrapped = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.ZIndex = 102
	titleLabel.Parent = window

	bodyLabel = Instance.new("TextLabel")
	bodyLabel.Size = UDim2.new(1, -40, 0, 70)
	bodyLabel.Position = UDim2.new(0, 20, 0, 62)
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.TextColor3 = Color3.fromRGB(205, 205, 218)
	bodyLabel.TextSize = 14
	bodyLabel.Font = Enum.Font.GothamMedium
	bodyLabel.Text = ""
	bodyLabel.TextWrapped = true
	bodyLabel.RichText = true
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Center
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Center
	bodyLabel.ZIndex = 102
	bodyLabel.Parent = window

	highlightFrame = Instance.new("Frame")
	highlightFrame.Size = UDim2.new(1, -40, 0, 40)
	highlightFrame.Position = UDim2.new(0, 20, 0, 142)
	highlightFrame.BackgroundColor3 = t.Panel
	highlightFrame.BorderSizePixel = 0
	highlightFrame.ZIndex = 102
	highlightFrame.Parent = window
	mc.corner(highlightFrame, 8)
	mc.stroke(highlightFrame, t.Stroke)

	highlightLabel = Instance.new("TextLabel")
	highlightLabel.Size = UDim2.fromScale(1, 1)
	highlightLabel.BackgroundTransparency = 1
	highlightLabel.TextColor3 = t.Purple
	highlightLabel.TextSize = 18
	highlightLabel.Font = Enum.Font.GothamBlack
	highlightLabel.Text = ""
	highlightLabel.TextWrapped = true
	highlightLabel.RichText = true
	highlightLabel.ZIndex = 103
	highlightLabel.Parent = highlightFrame

	footerLabel = Instance.new("TextLabel")
	footerLabel.Size = UDim2.new(1, -40, 0, 44)
	footerLabel.Position = UDim2.new(0, 20, 0, 192)
	footerLabel.BackgroundTransparency = 1
	footerLabel.TextColor3 = t.Muted
	footerLabel.TextSize = 11
	footerLabel.Font = Enum.Font.GothamBold
	footerLabel.Text = ""
	footerLabel.TextWrapped = true
	footerLabel.RichText = true
	footerLabel.TextXAlignment = Enum.TextXAlignment.Center
	footerLabel.TextYAlignment = Enum.TextYAlignment.Top
	footerLabel.Visible = false
	footerLabel.ZIndex = 102
	footerLabel.Parent = window

	continueBtn = Instance.new("TextButton")
	continueBtn.Size = UDim2.new(0.6, 0, 0, 38)
	continueBtn.AnchorPoint = Vector2.new(0.5, 1)
	continueBtn.Position = UDim2.new(0.5, 0, 1, -18)
	continueBtn.BackgroundColor3 = t.Purple
	continueBtn.BorderSizePixel = 0
	continueBtn.TextColor3 = t.Text
	continueBtn.TextSize = 13
	continueBtn.Font = Enum.Font.GothamBlack
	continueBtn.Text = "CONTINUE"
	continueBtn.AutoButtonColor = false
	continueBtn.ZIndex = 102
	continueBtn.Parent = window
	mc.corner(continueBtn, 8)
	continueBtn.MouseButton1Click:Connect(closeCurrentPopup)

	overlay.InputBegan:Connect(function(input)
		if not isShowing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = window.AbsolutePosition
		local size = window.AbsoluteSize
		local mouse = UserInputService:GetMouseLocation()
		if mouse.X < pos.X or mouse.X > pos.X + size.X or mouse.Y < pos.Y or mouse.Y > pos.Y + size.Y then
			closeCurrentPopup()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if not isShowing then return end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			closeCurrentPopup()
		end
	end)

	local smp = ReplicatedStorage:FindFirstChild("ShowMajorPopup")
	if smp then
		smp.OnClientEvent:Connect(function(data)
			if typeof(data) == "table" then
				table.insert(popupQueue, data)
				if not isShowing then
					showNextPopup()
				end
			end
		end)
	end
end

return { init = init }
