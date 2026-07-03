local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local uiState = require("@ui-state/uiState")
local mc = require("@ui/mobile/mobileComponents")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _bm(key, fallback) return BitKaisenLocale.tOrFallback(_L, "black_market." .. key, nil, fallback) end

local theme = mc.theme
local corner = mc.corner
local stroke = mc.stroke
local bindTap = mc.bindTap
local mobileButton = mc.mobileButton
local mobileCard = mc.mobileCard
local mobileLabel = mc.mobileLabel
local mobileSheet = mc.mobileSheet

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local getBlackMarket = ReplicatedStorage:WaitForChild("GetBlackMarket")
local blackMarketAction = ReplicatedStorage:WaitForChild("BlackMarketAction")

local gui: ScreenGui
local sheet: Frame
local scroll: ScrollingFrame
local moneyLabel: TextLabel
local wantedLabel: TextLabel
local statusLabel: TextLabel
local tabHolder: Frame

local isOpen = false
local busy = false
local currentTab = "BuyTools"
local currentData: { [string]: any }? = nil

local tabs: { [string]: TextButton } = {}
local TAB_NAMES = { "BuyTools", "BuyItems", "SellTools" }
local TAB_LABELS = { BuyTools = _bm("tab_buy_tools","BUY TOOLS"), BuyItems = _bm("tab_buy_items","BUY ITEMS"), SellTools = _bm("tab_sell_tools","SELL TOOLS") }

local refresh: () -> ()

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function formatMoney(value)
	value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
	if value % 1 == 0 then return tostring(math.floor(value)) end
	return string.format("%.2f", value)
end

local function rarityColor(rarity)
	if rarity == "Common"    then return Color3.fromRGB(180, 180, 190) end
	if rarity == "Uncommon"  then return Color3.fromRGB(120, 240, 160) end
	if rarity == "Rare"      then return Color3.fromRGB(120, 190, 255) end
	if rarity == "Epic"      then return Color3.fromRGB(190, 130, 255) end
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 90)  end
	if rarity == "SpecialGrade" or rarity == "Mythic" then return Color3.fromRGB(255, 90, 125) end
	return Color3.fromRGB(180, 180, 190)
end

local function clearScroll()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function setStatus(text, color)
	if statusLabel then
		statusLabel.Text = text or ""
		statusLabel.TextColor3 = color or theme.Muted
	end
end

----------------------------------------------------------------
-- ACTION FIRER
----------------------------------------------------------------
local function fireBlackMarketAction(actionId, targetId)
	if busy then
		setStatus("Please wait...", theme.Gold)
		return
	end
	busy = true
	setStatus("Processing...", theme.Gold)
	blackMarketAction:FireServer(actionId, targetId)
	task.delay(0.35, function()
		busy = false
		if isOpen then
			setStatus("Updated.", theme.Green)
			task.delay(1.2, function()
				if isOpen and statusLabel and statusLabel.Text == "Updated." then
					setStatus("")
				end
			end)
		end
	end)
end

----------------------------------------------------------------
-- TABS
----------------------------------------------------------------
local function setTab(name)
	currentTab = name
	for tabName, btn in pairs(tabs) do
		if tabName == name then
			btn.BackgroundColor3 = Color3.fromRGB(90, 40, 100)
			btn.TextColor3 = theme.Text
		else
			btn.BackgroundColor3 = theme.Button
			btn.TextColor3 = theme.SubText
		end
	end
end

local function buildTabs()
	tabHolder = Instance.new("Frame")
	tabHolder.Name = "BlackMarketTabs"
	tabHolder.Size = UDim2.new(1, -20, 0, 40)
	tabHolder.Position = UDim2.new(0, 10, 0, 50)
	tabHolder.BackgroundTransparency = 1
	tabHolder.Parent = sheet

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = tabHolder

	for i, tabName in ipairs(TAB_NAMES) do
		local btn = Instance.new("TextButton")
		btn.Name = tabName .. "Tab"
		btn.Size = UDim2.new(0.333, -4, 1, 0)
		btn.BackgroundColor3 = theme.Button
		btn.BorderSizePixel = 0
		btn.TextColor3 = theme.SubText
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBlack
		btn.Text = string.upper(TAB_LABELS[tabName])
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		btn.Parent = tabHolder
		corner(btn, 8)
		stroke(btn, theme.Stroke)
		bindTap(btn, function()
			setTab(tabName)
			refresh()
		end)
		tabs[tabName] = btn
	end
end

----------------------------------------------------------------
-- CARD BUILDERS
----------------------------------------------------------------
local function addEmptyCard(text, order)
	local card = mobileCard({ parent = scroll, order = order or 0 })
	mobileLabel({ parent = card, text = text, size = 14, color = theme.SubText, order = 1 })
end

local function addGoodsCard(props)
	local card = mobileCard({ parent = scroll, order = props.order, accentColor = props.accentColor })

	mobileLabel({
		parent = card, text = tostring(props.name),
		size = 15, color = theme.Text, font = Enum.Font.GothamBlack, order = 1,
	})
	mobileLabel({
		parent = card, text = props.priceText .. "  •  " .. props.tagText,
		size = 12, color = props.priceColor or theme.Green, font = Enum.Font.GothamBlack, order = 2,
	})
	mobileLabel({
		parent = card, text = tostring(props.desc or ""),
		size = 13, color = theme.SubText, order = 3,
	})

	if props.buttonEnabled then
		mobileButton({
			parent = card, text = props.buttonText, order = 4,
			size = UDim2.new(1, 0, 0, 46), color = props.buttonColor,
			textSize = 14, callback = props.callback,
		})
	else
		local btn = mobileButton({
			parent = card, text = props.buttonText, order = 4,
			size = UDim2.new(1, 0, 0, 46), color = theme.Button,
			textColor = theme.SubText, textSize = 14, callback = function() end,
		})
		btn.Active = false
	end
end

----------------------------------------------------------------
-- BUY TOOLS TAB
----------------------------------------------------------------
local function buildBuyToolsTab(data)
	local catalog = data.ToolCatalog or {}
	if #catalog <= 0 then
		addEmptyCard("No exclusive cursed tools are available right now.", 0)
		return
	end

	for i, tool in ipairs(catalog) do
		local color = rarityColor(tool.Rarity)
		addGoodsCard({
			order = i,
			name = tool.Name or "Unknown Tool",
			priceText = "$" .. tostring(tool.BlackMarketPrice or 0),
			priceColor = theme.Green,
			tagText = tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Cursed Tool"),
			desc = tool.EffectText or tool.Description,
			buttonText = tool.Owned and "OWNED" or "BUY",
			buttonColor = color,
			buttonEnabled = not tool.Owned,
			accentColor = tool.Owned and color or nil,
			callback = function() fireBlackMarketAction("BuyTool", tool.Id) end,
		})
	end
end

----------------------------------------------------------------
-- BUY ITEMS TAB
----------------------------------------------------------------
local function buildBuyItemsTab(data)
	local catalog = data.ItemCatalog or {}
	if #catalog <= 0 then
		addEmptyCard("No illegal items are available right now.", 0)
		return
	end

	for i, item in ipairs(catalog) do
		addGoodsCard({
			order = i,
			name = item.Name or "Unknown Item",
			priceText = "$" .. tostring(item.Price or 0),
			priceColor = theme.Green,
			tagText = _bm("tag_illegal","Illegal Item • Single Use"),
			desc = item.Description,
			buttonText = _bm("btn_buy_use","BUY & USE"),
			buttonColor = theme.Purple,
			buttonEnabled = true,
			callback = function() fireBlackMarketAction("BuyItem", item.Id) end,
		})
	end
end

----------------------------------------------------------------
-- SELL TOOLS TAB
----------------------------------------------------------------
local function buildSellToolsTab(data)
	local owned = data.OwnedTools or {}
	if #owned <= 0 then
		addEmptyCard("You do not own any cursed tools to sell.", 0)
		return
	end

	for i, tool in ipairs(owned) do
		addGoodsCard({
			order = i,
			name = tostring(tool.Name or "Cursed Tool") .. (tool.Equipped and "  [EQUIPPED]" or ""),
			priceText = "$" .. tostring(tool.SellValue or 0),
			priceColor = theme.Gold,
			tagText = tostring(tool.Rarity or "Common") .. " • " .. tostring(tool.Type or "Tool"),
			desc = tool.EffectText or tool.Description,
			buttonText = _bm("btn_sell","SELL"),
			buttonColor = theme.Bad,
			buttonEnabled = true,
			callback = function() fireBlackMarketAction("SellTool", tool.Id) end,
		})
	end
end

----------------------------------------------------------------
-- MAIN REFRESH
----------------------------------------------------------------
refresh = function()
	local ok, data = pcall(function() return getBlackMarket:InvokeServer() end)
	clearScroll()

	if not ok then
		warn("[MobileBlackMarketPanel] Failed to load black market:", data)
		addEmptyCard("Could not load the black market. Try again later.", 0)
		return
	end

	currentData = data or {}

	if moneyLabel then
		moneyLabel.Text = _bm("money_label","Money: $") .. formatMoney(currentData.Money or 0)
	end
	if wantedLabel then
		wantedLabel.Text = _bm("wanted_label","Wanted Level: ") .. tostring(currentData.WantedLevel or 0)
	end

	if currentTab == "BuyTools" then
		buildBuyToolsTab(currentData)
	elseif currentTab == "BuyItems" then
		buildBuyItemsTab(currentData)
	elseif currentTab == "SellTools" then
		buildSellToolsTab(currentData)
	end
end

----------------------------------------------------------------
-- OPEN / CLOSE
----------------------------------------------------------------
local function openPanel()
	if isOpen then return end
	isOpen = true
	setTab(currentTab)
	gui.Enabled = true
	sheet.Visible = true
	refresh()
end

local function closePanel()
	isOpen = false
	gui.Enabled = false
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
local function init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileBlackMarketGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 623
	gui.Enabled = false
	gui.Parent = playerGui

	sheet = mobileSheet({
		name = "MobileBlackMarketSheet",
		parent = gui,
		title = "BLACK MARKET",
		onClose = function()
			uiState.closeRoute()
		end,
	})

	scroll = sheet:FindFirstChildWhichIsA("ScrollingFrame") :: ScrollingFrame

	moneyLabel = Instance.new("TextLabel")
	moneyLabel.Size = UDim2.new(0.5, 0, 0, 20)
	moneyLabel.Position = UDim2.new(0, 10, 0, 50)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.TextColor3 = theme.Green
	moneyLabel.TextSize = 13
	moneyLabel.Font = Enum.Font.GothamBlack
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = _bm("money_label","Money: $") .. "0"
	moneyLabel.Parent = sheet

	wantedLabel = Instance.new("TextLabel")
	wantedLabel.Size = UDim2.new(0.5, -10, 0, 20)
	wantedLabel.Position = UDim2.new(0.5, 0, 0, 50)
	wantedLabel.BackgroundTransparency = 1
	wantedLabel.TextColor3 = theme.Bad
	wantedLabel.TextSize = 13
	wantedLabel.Font = Enum.Font.GothamBlack
	wantedLabel.TextXAlignment = Enum.TextXAlignment.Right
	wantedLabel.Text = _bm("wanted_label","Wanted Level: ") .. "0"
	wantedLabel.Parent = sheet

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 16)
	statusLabel.Position = UDim2.new(0, 10, 0, 92)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = theme.Muted
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Text = ""
	statusLabel.Parent = sheet

	buildTabs()

	scroll.Position = UDim2.new(0, 0, 0, 138)
	scroll.Size = UDim2.new(1, 0, 1, -138)

	sheet.Visible = true

	blackMarketAction.OnClientEvent:Connect(function()
		if isOpen then refresh() end
	end)

	uiState.subscribe(function(route)
		if route == "blackmarket" then
			openPanel()
		else
			closePanel()
		end
	end)
end

return { init = init }
