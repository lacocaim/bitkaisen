local vide = require("@packages/vide")

type Can<T> = T | () -> T
export type Gradient = {
	color: Can<(ColorSequence | Color3)>?,
	transparency: Can<(NumberSequence | number)>?,
	rotation: Can<number>?,
	offset: Can<Vector2>?,
}

local create = vide.create
local derive = vide.derive
local read = vide.read

return function(props: Gradient): UIGradient
	return create("UIGradient" :: "UIGradient")({
		Color = derive(function()
			local col = read(props.color) or Color3.new(1, 1, 1)
			if not col then
				return ColorSequence.new(Color3.new(1, 1, 1))
			end
			if typeof(col) == "ColorSequence" then
				return col
			else
				return ColorSequence.new(col)
			end
		end),
		Transparency = derive(function()
			local transp = read(props.transparency)
			if not transp then
				return NumberSequence.new(0)
			end
			if typeof(transp) == "NumberSequence" then
				return transp
			else
				return NumberSequence.new(transp)
			end
		end),
		Rotation = derive(function()
			return read(props.rotation) or 0
		end),
		Offset = props.offset,
	})
end
