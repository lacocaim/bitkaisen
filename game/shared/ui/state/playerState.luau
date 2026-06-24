local vide = require("@packages/vide")
local remotes = require("@ui-state/remotes")

local source = vide.source

local LOG_MAX_LINES = 120

local stats = source(nil :: { [string]: any }?)
local previousStats = source(nil :: { [string]: any }?)
local lifeLog = source({} :: { string })
local logVersion = source(0)

local function alive()
	local s = stats()
	if not s then return true end
	return s.Alive ~= false
end

local function age()
	local s = stats()
	if not s then return 0 end
	return tonumber(s.Age) or 0
end

local function name()
	local s = stats()
	if not s then return "" end
	local first = s.FirstName or ""
	local last = s.LastName or ""
	if first == "" and last == "" then return "Unknown" end
	return first .. " " .. last
end

local function pushLog(message: string)
	local log = table.clone(lifeLog())
	table.insert(log, message)
	while #log > LOG_MAX_LINES do
		table.remove(log, 1)
	end
	lifeLog(log)
	logVersion(logVersion() + 1)
end

local function clearLog()
	lifeLog({})
	logVersion(logVersion() + 1)
end

local function update(newStats: { [string]: any }?, logMessage: string?, forceResetLog: boolean?)
	if not newStats then return end
	previousStats(stats())
	stats(newStats)

	if forceResetLog then
		clearLog()
	end
	if logMessage and logMessage ~= "" then
		pushLog(logMessage)
	end
end

local function connect()
	local ule = remotes.updateLifeEvent()
	if ule then
		ule.OnClientEvent:Connect(function(updatedStats, logMessage, forceResetLog)
			update(updatedStats, logMessage, forceResetLog)
		end)
	end
end

return {
	stats = stats,
	previousStats = previousStats,
	lifeLog = lifeLog,
	logVersion = logVersion,
	alive = alive,
	age = age,
	name = name,

	pushLog = pushLog,
	clearLog = clearLog,
	update = update,
	connect = connect,
}
