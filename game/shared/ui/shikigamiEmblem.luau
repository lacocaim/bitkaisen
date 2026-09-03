-- Update 30 -- seals for the Ten Shadows.
--
-- The shikigami artwork slots are empty and there is no honest way to fill them: the site
-- photographs came from Creative Commons, and nobody has published a free photograph of
-- Mahoraga.
--
-- The first attempt at filling the gap drew each creature out of coloured rectangles. It
-- did not work: at the 56px the dossier gives it, four or five filled shapes in one colour
-- merge into a blob, and "toad" came out as a purple lozenge with two bumps. So this does
-- not pretend to illustrate the creature. It stamps it, the way the world-mode cards
-- already stamp 個人記録 and 封印済: a double ring with the shikigami's own character in
-- the middle. A glyph stays readable at any size, which a drawing of a toad does not.
--
-- The characters are the ones the shikigami are actually named with, so Divine Dogs (玉犬)
-- is stamped 犬 and Tiger Funeral (虎杖) is stamped 虎.
--
-- If real artwork ever lands, drop the id into BitKaisenIncidentMap.SHIKIGAMI_ART and the
-- panels use the image instead. Nothing here has to be removed.
local shikigamiEmblem = {}

local SEALS = {
	["Divine Dogs"]   = "犬",
	["Nue"]           = "鵺",
	["Toad"]          = "蟇",
	["Great Serpent"] = "蛇",
	["Max Elephant"]  = "象",
	["Rabbit Escape"] = "兎",
	["Round Deer"]    = "鹿",
	["Piercing Ox"]   = "牛",
	["Tiger Funeral"] = "虎",
	["Mahoraga"]      = "魔",
}

-- Anything outside the ten still gets a mark rather than an empty box: just "shadow".
local FALLBACK = "影"

function shikigamiEmblem.has(name: string?): boolean
	return SEALS[tostring(name or "")] ~= nil
end

function shikigamiEmblem.characterFor(name: string?): string
	return SEALS[tostring(name or "")] or FALLBACK
end

-- Draws into `parent` and returns the seal, so a caller can remove just the emblem without
-- touching the rest of the card.
function shikigamiEmblem.draw(parent: GuiObject, name: string?, color: Color3?, zIndex: number?): Frame
	local base = color or Color3.fromRGB(178, 122, 255)
	local z = zIndex or 6

	local seal = Instance.new("Frame")
	seal.Name = "Emblem"
	seal.AnchorPoint = Vector2.new(0.5, 0.5)
	seal.Position = UDim2.fromScale(0.5, 0.5)
	seal.Size = UDim2.fromScale(0.82, 0.82)
	seal.BackgroundColor3 = Color3.fromRGB(8, 7, 12)
	seal.BackgroundTransparency = 0.15
	seal.BorderSizePixel = 0
	seal.ZIndex = z
	seal.Parent = parent

	-- Square it off whatever box it was given, so a wide card does not stretch the ring
	-- into an ellipse.
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.DominantAxis = Enum.DominantAxis.Height
	ratio.Parent = seal

	Instance.new("UICorner", seal).CornerRadius = UDim.new(1, 0)

	local outer = Instance.new("UIStroke")
	outer.Color = base
	outer.Thickness = 1.5
	outer.Transparency = 0.1
	outer.Parent = seal

	local inner = Instance.new("Frame")
	inner.Name = "InnerRing"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.84, 0.84)
	inner.BackgroundTransparency = 1
	inner.BorderSizePixel = 0
	inner.ZIndex = z + 1
	inner.Parent = seal
	Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = base
	innerStroke.Thickness = 0.8
	innerStroke.Transparency = 0.55
	innerStroke.Parent = inner

	local glyph = Instance.new("TextLabel")
	glyph.Name = "Glyph"
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromScale(0.62, 0.62)
	glyph.BackgroundTransparency = 1
	glyph.Text = shikigamiEmblem.characterFor(name)
	glyph.TextColor3 = base
	glyph.TextScaled = true
	glyph.Font = Enum.Font.GothamBlack
	glyph.ZIndex = z + 2
	glyph.Parent = seal

	return seal
end

return shikigamiEmblem
