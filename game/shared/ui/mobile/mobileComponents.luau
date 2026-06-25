local TweenService = game:GetService("TweenService")

local theme = {
	Bg = Color3.fromRGB(7, 7, 10),
	Panel = Color3.fromRGB(15, 15, 22),
	Card = Color3.fromRGB(22, 22, 30),
	CardHover = Color3.fromRGB(28, 28, 38),
	Stroke = Color3.fromRGB(48, 48, 64),
	StrokeSoft = Color3.fromRGB(34, 34, 46),
	Text = Color3.fromRGB(245, 243, 252),
	SubText = Color3.fromRGB(165, 165, 185),
	Muted = Color3.fromRGB(110, 110, 130),
	Gold = Color3.fromRGB(255, 207, 105),
	Purple = Color3.fromRGB(178, 122, 255),
	Green = Color3.fromRGB(120, 240, 160),
	Blue = Color3.fromRGB(120, 190, 255),
	Red = Color3.fromRGB(145, 32, 45),
	Bad = Color3.fromRGB(230, 75, 90),
	Orange = Color3.fromRGB(255, 160, 78),
	Button = Color3.fromRGB(38, 34, 52),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or theme.Stroke
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function mobileButton(props: {
	parent: GuiObject,
	text: string,
	size: UDim2?,
	position: UDim2?,
	color: Color3?,
	textColor: Color3?,
	textSize: number?,
	order: number?,
	callback: () -> (),
}): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = props.size or UDim2.new(1, -20, 0, 44)
	btn.Position = props.position or UDim2.new(0, 10, 0, 0)
	btn.BackgroundColor3 = props.color or theme.Button
	btn.BorderSizePixel = 0
	btn.Text = props.text
	btn.TextColor3 = props.textColor or theme.Text
	btn.TextSize = props.textSize or 15
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.TextWrapped = true
	btn.LayoutOrder = props.order or 0
	btn.Parent = props.parent
	corner(btn, 10)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = theme.CardHover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = props.color or theme.Button }):Play()
	end)
	btn.MouseButton1Click:Connect(props.callback)

	return btn
end

local function mobileCard(props: {
	parent: GuiObject,
	height: number?,
	color: Color3?,
	accentColor: Color3?,
	order: number?,
}): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, props.height or 0)
	if not props.height or props.height == 0 then
		card.AutomaticSize = Enum.AutomaticSize.Y
	end
	card.BackgroundColor3 = props.color or theme.Card
	card.BorderSizePixel = 0
	card.LayoutOrder = props.order or 0
	card.Parent = props.parent
	corner(card, 10)
	stroke(card, props.accentColor or theme.Stroke)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = card

	return card
end

local function mobileLabel(props: {
	parent: GuiObject,
	text: string | () -> string,
	size: number?,
	color: Color3 | (() -> Color3)?,
	font: Enum.Font?,
	order: number?,
	wrap: boolean?,
}): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.TextSize = props.size or 14
	label.Font = props.font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = if props.wrap ~= nil then props.wrap else true
	label.RichText = true
	label.LayoutOrder = props.order or 0
	label.Parent = props.parent

	if typeof(props.text) == "function" then
		task.spawn(function()
			while label and label.Parent do
				label.Text = (props.text :: () -> string)()
				task.wait(0.5)
			end
		end)
	else
		label.Text = props.text :: string
	end

	if typeof(props.color) == "function" then
		task.spawn(function()
			while label and label.Parent do
				label.TextColor3 = (props.color :: () -> Color3)()
				task.wait(0.5)
			end
		end)
	else
		label.TextColor3 = (props.color :: Color3?) or theme.Text
	end

	return label
end

local function mobileList(parent: GuiObject): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -50)
	scroll.Position = UDim2.new(0, 0, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = theme.Stroke
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = scroll

	return scroll
end

local function mobileHeader(parent: GuiObject, titleText: string, onClose: () -> ()): Frame
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 48)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.Parent = parent
	corner(header, 10)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = theme.Gold
	title.TextSize = 18
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(34, 34)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
	closeBtn.BackgroundColor3 = theme.Card
	closeBtn.TextColor3 = theme.Bad
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Text = "X"
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = header
	corner(closeBtn, 999)
	closeBtn.MouseButton1Click:Connect(onClose)

	return header
end

local function mobileSheet(props: {
	name: string,
	parent: GuiObject,
	title: string,
	onClose: () -> (),
}): Frame
	local sheet = Instance.new("Frame")
	sheet.Name = props.name
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BackgroundColor3 = theme.Bg
	sheet.BorderSizePixel = 0
	sheet.Visible = false
	sheet.Parent = props.parent
	corner(sheet, 0)

	mobileHeader(sheet, props.title, props.onClose)
	mobileList(sheet)

	return sheet
end

return {
	theme = theme,
	corner = corner,
	stroke = stroke,
	mobileButton = mobileButton,
	mobileCard = mobileCard,
	mobileLabel = mobileLabel,
	mobileList = mobileList,
	mobileHeader = mobileHeader,
	mobileSheet = mobileSheet,
}
