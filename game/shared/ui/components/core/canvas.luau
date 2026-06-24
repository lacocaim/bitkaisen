local vide = require("@packages/vide")
local base = require("../base")

type Can<T> = T | () -> T

return base(function(p: {
	group_transparency: Can<number>?,
	transparency: Can<number>?,
})
	return vide.create("CanvasGroup")({
		GroupTransparency = p.group_transparency,
		BackgroundTransparency = p.transparency,
	})
end)
