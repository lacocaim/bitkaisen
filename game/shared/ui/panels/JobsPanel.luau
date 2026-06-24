local vide = require("@packages/vide")
local theme = require("@ui/theme")
local remotes = require("@ui-state/remotes")
local uiState = require("@ui-state/uiState")
local factory = require("@ui-panels/panelFactory")
local OverlayPanel = require("@ui-components/shell/OverlayPanel")

local function buildJobs(parent: Frame)
	local scroll, title = factory.createCardList(parent, "JOBS & CAREER")

	local getJobs = remotes.getJobs()
	if not getJobs then
		factory.createMessageCard(scroll, "Job system unavailable.")
		return
	end

	local ok, payload = pcall(function() return getJobs:InvokeServer() end)
	if not ok or typeof(payload) ~= "table" then
		factory.createMessageCard(scroll, "Failed to load jobs.")
		return
	end

	local currentJob = payload.CurrentJob
	local jobs = payload.Jobs or payload
	local order = 1

	if currentJob and typeof(currentJob) == "table" then
		factory.createCard(scroll, order, {
			title = "Current: " .. tostring(currentJob.Name or "None"),
			subtitle = "Salary: $" .. tostring(currentJob.Salary or 0) .. " | Performance: " .. tostring(currentJob.Performance or 0) .. "%",
			accentColor = theme.Green,
			actions = {
				{ label = "QUIT", callback = function()
					local ja = remotes.jobAction()
					if ja then ja:FireServer("quit") end
				end },
			},
		})
		order += 1
	end

	if payload.CanGoRogue then
		factory.createCard(scroll, order, {
			title = "Go Rogue",
			subtitle = "Leave society and become a curse user",
			accentColor = theme.Bad,
			actions = {
				{ label = "GO ROGUE", callback = function()
					local ja = remotes.jobAction()
					if ja then ja:FireServer("go_rogue") end
					uiState.closeRoute()
				end },
			},
		})
		order += 1
	end

	if typeof(jobs) == "table" then
		for _, job in jobs do
			factory.createCard(scroll, order, {
				title = tostring(job.Name or "Unknown Job"),
				subtitle = "Salary: $" .. tostring(job.Salary or 0),
				body = tostring(job.Requirements or ""),
				actions = job.CanApply ~= false and {
					{ label = "APPLY", callback = function()
						local ja = remotes.jobAction()
						if ja then ja:FireServer("apply", job.Id) end
					end },
				} or nil,
			})
			order += 1
		end
	end

	if order == 1 then
		factory.createMessageCard(scroll, "No jobs available.")
	end
end

local function init()
	OverlayPanel.registerPanelBuilder("jobs", buildJobs)
end

return { init = init }
