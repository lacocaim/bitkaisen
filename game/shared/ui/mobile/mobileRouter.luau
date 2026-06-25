local uiState = require("@ui-state/uiState")

local function init(_playerGui: PlayerGui)
	-- The existing PC panels each create their own ScreenGui and subscribe
	-- to uiState routes independently, so they work on mobile out of the box.
	-- This router is a placeholder for future mobile-native panel overrides.
	-- As mobile-specific sheets are built, they'll register here and
	-- suppress the PC panel's ScreenGui for that route.
end

return { init = init }
