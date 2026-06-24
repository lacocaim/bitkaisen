local component = require("@ui-components/base")
local vide = require("@packages/vide")

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T

return component(function(
	p: {
		color: Can<Color3>?,
		transparency: Can<number>?,
		acc: boolean?,

		text: Can<string | number>,
		size: Can<number>?,
		font: Can<Font>?,
		truncate: "split" | "end"?,
		wraps: boolean?,

		xalign: "left" | "center" | "right"?,
		yalign: "top" | "center" | "bottom"?,

		rich: Can<boolean>?,
		weight: Can<number>?,
		italic: Can<boolean>?,

		thickness: Can<number>?,

		auto: ("x" | "y" | "xy")?,
	},
	_
)
	return create("TextLabel" :: "TextLabel")({
		AutomaticSize = function()
			if p.auto then
				if p.auto == "x" then
					return Enum.AutomaticSize.X
				elseif p.auto == "y" then
					return Enum.AutomaticSize.Y
				else
					return Enum.AutomaticSize.XY
				end
			else
				return Enum.AutomaticSize.None
			end
		end,
		AutoLocalize = false,

		BackgroundTransparency = 1,

		Text = p.text,
		TextColor3 = p.color,
		TextTransparency = p.transparency,
		TextSize = function()
			return math.round(read(p.size) or 24)
		end,
		TextTruncate = if p.truncate == "split"
			then Enum.TextTruncate.SplitWord
			elseif p.truncate == "end" then Enum.TextTruncate.AtEnd
			else Enum.TextTruncate.None,

		TextXAlignment = if p.xalign == "left"
			then Enum.TextXAlignment.Left
			elseif p.xalign == "center" then Enum.TextXAlignment.Center
			elseif p.xalign == "right" then Enum.TextXAlignment.Right
			else nil,
		TextYAlignment = if p.yalign == "top"
			then Enum.TextYAlignment.Top
			elseif p.yalign == "center" then Enum.TextYAlignment.Center
			elseif p.yalign == "bottom" then Enum.TextYAlignment.Bottom
			else nil,
		TextWrapped = p.wraps,

		RichText = p.rich,

		FontFace = p.font,
		unpack(p),
	})
end)
