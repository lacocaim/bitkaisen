local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charm = require("@packages/charm")
local delta_compress = require("@packages/delta-compress")
local client_blink = require("@client-blink")

local account = charm.signal(nil)

local function init()
	client_blink.account.sync.on(function(diff)
		local current = charm.untracked(account) or {}
		local patched = delta_compress.patchImmutable(current, diff)
		account(patched)
	end)

	task.defer(function()
		client_blink.account.ready.fire()
	end)
end

return {
	init = init,
	account = account,
}
