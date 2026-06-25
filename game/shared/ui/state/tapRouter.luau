local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local TAP_MAX_MOVE = 12
local TAP_MAX_TIME = 0.5
local DEBOUNCE = 0.2

local registry: { [GuiObject]: () -> () } = {}
local startPos: Vector3? = nil
local startTime = 0
local lastFireTime = 0
local connected = false

local function findScreenGui(obj: Instance): ScreenGui?
	local cur = obj
	while cur do
		if cur:IsA("ScreenGui") then return cur :: ScreenGui end
		cur = cur.Parent
	end
	return nil
end

local function onInputBegan(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		startPos = input.Position
		startTime = os.clock()
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if not startPos then return end

	local now = os.clock()
	local pos = input.Position
	local dx = math.abs(pos.X - startPos.X)
	local dy = math.abs(pos.Y - startPos.Y)
	startPos = nil

	if dx > TAP_MAX_MOVE or dy > TAP_MAX_MOVE then return end
	if (now - startTime) > TAP_MAX_TIME then return end
	if (now - lastFireTime) < DEBOUNCE then return end

	local inset = GuiService:GetGuiInset()
	local hx = math.floor(pos.X + inset.X)
	local hy = math.floor(pos.Y + inset.Y)

	local objects = playerGui:GetGuiObjectsAtPosition(hx, hy)
	for _, obj in objects do
		local cb = registry[obj]
		if cb then
			local sg = findScreenGui(obj)
			if sg and sg.Enabled then
				lastFireTime = now
				task.spawn(cb)
				return
			end
		end
	end
end

local function ensureConnected()
	if connected then return end
	connected = true
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
end

local tapRouter = {}

function tapRouter.register(button: GuiObject, callback: () -> ())
	ensureConnected()
	registry[button] = callback
end

function tapRouter.unregister(button: GuiObject)
	registry[button] = nil
end

return tapRouter
