local types = require("@global/shared/types")
local objects = require("@utils/objects")

export type Account = types.Account
export type TransactionFunction = (player: Player, () -> ()) -> ()
export type Transaction = (txFor: TransactionFunction) -> ()
export type ProfileData = {
	account: Account,
	migrationVersion: number,
}

local accountTemplate: Account = objects.deepFreeze({
	currencies = {
		gold = 0,
		gems = 0,
	},
	units = {},
	settings = {},
	slotbar = {
		{
			unitId = nil,
			locked = false,
		},
		{
			unitId = nil,
			locked = false,
		},
		{
			unitId = nil,
			locked = false,
		},
		{
			unitId = nil,
			locked = true,
		},
		{
			unitId = nil,
			locked = true,
		},
		{
			unitId = nil,
			locked = true,
		},
	},
})
local ok, reason = types.accountSchema:matches(accountTemplate)
if not ok then
	error(reason)
end

return {
	template = objects.deepFreeze({
		account = accountTemplate,
		migrationVersion = 0,
	}) :: ProfileData,
	accountSchema = types.accountSchema,
}
