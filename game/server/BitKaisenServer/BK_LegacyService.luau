local MODULE = {}

function MODULE.Init(context)
	if context and context.IS_DEBUG then print("[BK_LegacyService] Loaded.") end
end

return MODULE
