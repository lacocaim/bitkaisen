-- ModuleScript: BitKaisenRelationshipCache
-- Shared client cache for relationship payloads used by Relationships and Affiliations UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getRelationships = ReplicatedStorage:WaitForChild("GetRelationships")
local updateLifeEvent = ReplicatedStorage:WaitForChild("UpdateLifeEvent", 20)
local relationshipAction = ReplicatedStorage:WaitForChild("RelationshipAction", 20)

local CACHE_TTL = 12

local cachePayload = nil
local cacheTime = 0
local inFlight = false
local waiters = {}

local RelationshipCache = {}

local function wakeWaiters(ok, payload)
	local queued = waiters
	waiters = {}
	for _, waiter in ipairs(queued) do
		waiter:Fire(ok, payload)
		waiter:Destroy()
	end
end

function RelationshipCache.Invalidate()
	cacheTime = 0
end

function RelationshipCache.Get(forceRefresh)
	if not forceRefresh and cachePayload ~= nil and (os.clock() - cacheTime) <= CACHE_TTL then
		return true, cachePayload, true
	end

	if not forceRefresh and cachePayload ~= nil then
		if not inFlight then
			task.spawn(function()
				RelationshipCache.Get(true)
			end)
		end
		return true, cachePayload, true
	end

	if inFlight then
		local waiter = Instance.new("BindableEvent")
		table.insert(waiters, waiter)
		local ok, payload = waiter.Event:Wait()
		return ok, payload, ok and payload == cachePayload
	end

	inFlight = true
	local ok, payload = pcall(function()
		return getRelationships:InvokeServer()
	end)
	inFlight = false

	if ok then
		cachePayload = payload
		cacheTime = os.clock()
	else
		payload = nil
	end

	wakeWaiters(ok, payload)
	return ok, payload, false
end

function RelationshipCache.Warm(forceRefresh)
	task.spawn(function()
		RelationshipCache.Get(forceRefresh == true)
	end)
end

if updateLifeEvent then
	updateLifeEvent.OnClientEvent:Connect(function()
		RelationshipCache.Invalidate()
		task.delay(0.2, function()
			RelationshipCache.Warm(false)
		end)
	end)
end

task.defer(function()
	RelationshipCache.Warm(false)
end)

task.delay(2, function()
	RelationshipCache.Warm(false)
end)

if relationshipAction then
	relationshipAction.OnClientEvent:Connect(function()
		RelationshipCache.Invalidate()
	end)
end

return RelationshipCache
