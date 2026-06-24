local vide = require("@packages/vide")

type Can<T> = T | () -> T
type Stroke = {
	mode: "context" | "border"?,
	join: "bevel" | "miter" | "round"?,
	z: Can<number>?,
	border: "center" | "inner" | "outer"?,
	sizing: "scaled" | "fixed"?,
	thickness: Can<number>?,
	transparency: Can<number>?,
	offset: Can<number>?,
	color: Can<Color3>?,

	[any]: any,
}

return function(p: Stroke)
	return vide.create("UIStroke" :: "UIStroke")({
		ApplyStrokeMode = if p.mode == "border" then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual,
		StrokeSizingMode = if p.sizing == "scaled"
			then Enum.StrokeSizingMode.ScaledSize
			else Enum.StrokeSizingMode.FixedSize,
		LineJoinMode = if p.join == "bevel"
			then Enum.LineJoinMode.Bevel
			elseif p.join == "miter" then Enum.LineJoinMode.Miter
			else Enum.LineJoinMode.Round,

		BorderStrokePosition = if p.border == "center"
			then Enum.BorderStrokePosition.Center
			elseif p.border == "inner" then Enum.BorderStrokePosition.Inner
			else Enum.BorderStrokePosition.Outer,

		ZIndex = p.z or 1,
		Thickness = p.thickness or 1,
		Color = p.color or Color3.new(1, 1, 1),
		BorderOffset = function()
			return UDim.new(0, vide.read(p.offset) or 0)
		end,
		Transparency = p.transparency,
		unpack(p),
	})
end
