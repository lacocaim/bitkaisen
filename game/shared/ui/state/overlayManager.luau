-- Single-overlay manager: ensures only one full-screen mobile overlay is open
-- at a time. Opening a new one auto-closes the previous, preventing the
-- opaque-stack "black screen" problem.

local current: { name: string, closeFn: () -> () }? = nil

local overlayManager = {}

function overlayManager.show(name: string, openFn: () -> (), closeFn: () -> ())
	if current and current.name ~= name then
		pcall(current.closeFn)
	end
	current = { name = name, closeFn = closeFn }
	openFn()
end

function overlayManager.closeAll()
	if current then
		pcall(current.closeFn)
		current = nil
	end
end

function overlayManager.currentName(): string?
	return current and current.name
end

return overlayManager
