local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Jabby = require(ReplicatedStorage.Packages.Jabby)

local scheduler = require(ReplicatedStorage.ecs.scheduler)
local world = require(ReplicatedStorage.ecs.world)
local types = require(ReplicatedStorage.types)

local function registerDebugger()
	if RunService:IsClient() then
		local client = Jabby.obtain_client()

		local function createWidget(_, state: Enum.UserInputState)
			if state ~= Enum.UserInputState.Begin then
				return
			end

			client.spawn_app(client.apps.home, nil)
		end

		ContextActionService:BindAction("Open Jabby", createWidget, false, Enum.KeyCode.F4)
		print("Initialized Jabby Debugger")
	end

	Jabby.register({
		applet = Jabby.applets.world,
		name = "world",
		configuration = {
			world = world,
		},
	})
end

local function addSystems(folders: { Folder })
	local systems: { types.System } = {}
	for _, folder in ipairs(folders) do
		for _, system in folder:GetDescendants() do
			if not system:IsA("ModuleScript") then
				continue
			end

			local success, result: types.System = pcall(require, system)

			if success then
				table.insert(systems, result)
			else
				warn("Failed to require system:", system.Name, result)
			end
		end
	end
	return systems
end

return function(systemFolders)
	local systems = addSystems(systemFolders)

	if #systems ~= 0 then
		scheduler:addSystems(systems)
	end

	registerDebugger()
end
