local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local theme = require("@ui/theme")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LOGO_ASSET = "rbxassetid://118796008605770"
local MIN_SHOW_TIME = 1.2
local SAFETY_TIMEOUT = if RunService:IsStudio() then 4 else 10

local BG = theme.Bg
local BAR_BG = Color3.fromRGB(25, 25, 35)
local BAR_FILL = theme.Purple
local BAR_FILL_END = Color3.fromRGB(120, 190, 255)

local gui = nil
local barFill = nil
local logoRef = nil

local currentTarget = 0
local currentFill = 0
local showStartTime = 0
local finished = false
local destroyed = false
local renderConn = nil

local loadingScreen = {}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function buildUI(mode)
	local isMobile = (mode == "Mobile")

	gui = Instance.new("ScreenGui")
	gui.Name = "BitKaisenLoading"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 6000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = BG
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local logoSize = if isMobile then UDim2.new(0, 300, 0, 300) else UDim2.new(0, 440, 0, 440)

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.Image = LOGO_ASSET
	logo.Size = logoSize
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.new(0.5, 0, 0.42, 0)
	logo.BackgroundTransparency = 1
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 3
	logo.Parent = bg
	logoRef = logo

	local logoCorner = Instance.new("UICorner")
	logoCorner.CornerRadius = UDim.new(0, 16)
	logoCorner.Parent = logo

	task.spawn(function()
		while not destroyed do
			local rockRight = TweenService:Create(logo, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Rotation = 8,
			})
			rockRight:Play()
			rockRight.Completed:Wait()
			if destroyed then break end
			local rockLeft = TweenService:Create(logo, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Rotation = -8,
			})
			rockLeft:Play()
			rockLeft.Completed:Wait()
		end
	end)

	local barWidth = if isMobile then 0.7 else 0.35

	local barTrack = Instance.new("Frame")
	barTrack.Name = "BarTrack"
	barTrack.Size = UDim2.new(barWidth, 0, 0, 10)
	barTrack.AnchorPoint = Vector2.new(0.5, 0)
	barTrack.Position = UDim2.new(0.5, 0, 0.42, (if isMobile then 165 else 235))
	barTrack.BackgroundColor3 = BAR_BG
	barTrack.BorderSizePixel = 0
	barTrack.ZIndex = 3
	barTrack.Parent = bg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 999)
	barCorner.Parent = barTrack

	barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = BAR_FILL
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 4
	barFill.Parent = barTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 999)
	fillCorner.Parent = barFill

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(BAR_FILL, BAR_FILL_END)
	grad.Parent = barFill

	task.spawn(function()
		local offset = 0
		while not destroyed do
			offset = (offset + 0.01) % 1
			grad.Offset = Vector2.new(offset, 0)
			task.wait(0.03)
		end
	end)

	renderConn = RunService.RenderStepped:Connect(function(dt)
		if destroyed then return end
		local diff = currentTarget - currentFill
		if math.abs(diff) < 0.001 then
			currentFill = currentTarget
		else
			currentFill = lerp(currentFill, currentTarget, math.clamp(dt * 3, 0, 1))
		end
		barFill.Size = UDim2.new(math.clamp(currentFill, 0, 1), 0, 1, 0)
	end)

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ logo })
		end)
		if not destroyed and currentTarget < 0.2 then
			currentTarget = 0.2
		end
	end)
end

loadingScreen._statusText = "Preparing..."

function loadingScreen.show(mode)
	if gui then return end
	finished = false
	destroyed = false
	currentTarget = 0.05
	currentFill = 0
	showStartTime = os.clock()
	buildUI(mode)
end

function loadingScreen.setProgress(fraction, _label)
	if destroyed then return end
	currentTarget = math.clamp(fraction, currentTarget, 1)
end

local bumpIndex = 0

function loadingScreen.bump(_label)
	if destroyed then return end
	bumpIndex = bumpIndex + 1
	local base = 0.25
	local step = 0.12
	local target = math.clamp(base + step * bumpIndex, 0, 0.88)
	currentTarget = math.max(currentTarget, target)
end

local function cleanup()
	destroyed = true
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	barFill = nil
	logoRef = nil
end

function loadingScreen.finish()
	if finished or destroyed then return end
	finished = true

	local elapsed = os.clock() - showStartTime
	local remaining = MIN_SHOW_TIME - elapsed
	if remaining > 0 then
		task.wait(remaining)
	end

	currentTarget = 1
	task.wait(0.5)

	if destroyed then return end

	local bg = gui and gui:FindFirstChild("Background")
	if bg then
		for _, child in bg:GetChildren() do
			if child:IsA("GuiObject") then
				pcall(function()
					TweenService:Create(child, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1,
					}):Play()
				end)
			end
			if child:IsA("ImageLabel") then
				pcall(function()
					TweenService:Create(child, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play()
				end)
			end
		end
		TweenService:Create(bg, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	end

	task.wait(0.4)
	cleanup()
end

task.defer(function()
	task.wait(SAFETY_TIMEOUT)
	if not finished and not destroyed then
		finished = true
		cleanup()
	end
end)

return loadingScreen
