local gt = require("@packages/gt")

export type SlotbarSlot = {
	unitId: string?,
	locked: boolean,
}

export type Unit = {
	id: string,
	typeId: string,
	level: number,
	experience: number,
}

export type Account = {
	currencies: {
		gold: number,
		gems: number,
	},
	units: { [string]: Unit },
	settings: { [string]: any },
	slotbar: { SlotbarSlot },
}

local unitSchema = gt.build(gt.object({
	id = gt.string(),
	typeId = gt.string(),
	level = gt.number(),
	experience = gt.number(),
}))

local slotbarSlotSchema = gt.build(gt.object({
	unitId = gt.optional(gt.string()),
	locked = gt.boolean(),
}))

local accountSchema = gt.build(gt.object({
	currencies = gt.object({
		gold = gt.number(),
		gems = gt.number(),
	}),
	units = gt.object({}),
	settings = gt.object({}),
	slotbar = gt.array(slotbarSlotSchema),
}))

return {
	accountSchema = accountSchema,
	unitSchema = unitSchema,
}
