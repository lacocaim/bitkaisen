local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charm = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("charm"))
local delta_compress = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("delta-compress"))
local client_blink = require(ReplicatedStorage:WaitForChild("client-blink"))

local account = charm.signal(nil)

local function init()
	client_blink.account.sync.on(function(payload)
		local current = charm.untracked(account)
		if current == nil then
			account(payload)
		else
			local ok, patched = pcall(delta_compress.applyImmutable, current, payload)
			if ok then
				account(patched)
			else
				warn("[accountController] applyImmutable failed, treating as full state:", patched)
				account(payload)
			end
		end
	end)

	task.defer(function()
		client_blink.account.ready.fire()
	end)
end

return {
	init = init,
	account = account,
}
