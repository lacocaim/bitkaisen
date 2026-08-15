local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local uiState = require("@ui-state/uiState")
local remotes = require("@ui-state/remotes")
local playerState = require("@ui-state/playerState")
local responsiveScale = require("@ui/responsiveScale")
local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _mas(key, fallback) return BitKaisenLocale.tOrFallback(_L, "mastery." .. key, nil, fallback) end

local BitKaisenTechniqueEffects = require(ReplicatedStorage:WaitForChild("BitKaisenTechniqueEffects"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isOpen = false
local currentStats = nil

local ROUTE = "technique_mastery"

local THEME = {
	Bg = Color3.fromRGB(8, 8, 13),
	Bg2 = Color3.fromRGB(13, 13, 21),
	Panel = Color3.fromRGB(18, 18, 28),
	Panel2 = Color3.fromRGB(24, 24, 36),
	Panel3 = Color3.fromRGB(31, 29, 46),
	Stroke = Color3.fromRGB(64, 58, 88),
	StrokeSoft = Color3.fromRGB(42, 40, 58),

	Purple = Color3.fromRGB(174, 121, 255),
	PurpleDark = Color3.fromRGB(52, 34, 80),
	PurpleSoft = Color3.fromRGB(110, 78, 165),
	Gold = Color3.fromRGB(255, 207, 105),
	Green = Color3.fromRGB(112, 236, 153),
	Blue = Color3.fromRGB(118, 180, 255),
	Red = Color3.fromRGB(232, 82, 108),

	Text = Color3.fromRGB(242, 242, 250),
	SubText = Color3.fromRGB(177, 176, 196),
	Muted = Color3.fromRGB(116, 114, 138),
}

local STAGE_DATA = {
	{
		Min = 0,
		Max = 9,
		Name = "Dormant Control",
		Short = "Dormant",
		Description = "You barely understand how your cursed technique reacts.",
		Color = Color3.fromRGB(125, 125, 150),
	},
	{
		Min = 10,
		Max = 24,
		Name = "Basic Control",
		Short = "Basic",
		Description = "You can use your technique, but it is still unstable.",
		Color = Color3.fromRGB(120, 170, 255),
	},
	{
		Min = 25,
		Max = 49,
		Name = "Refined Control",
		Short = "Refined",
		Description = "Your technique is becoming reliable during assignments.",
		Color = Color3.fromRGB(130, 220, 170),
	},
	{
		Min = 50,
		Max = 74,
		Name = "Advanced Application",
		Short = "Advanced",
		Description = "Your technique is starting to define your sorcerer identity.",
		Color = Color3.fromRGB(180, 130, 255),
	},
	{
		Min = 75,
		Max = 94,
		Name = "Elite Mastery",
		Short = "Elite",
		Description = "You are dangerous even among trained sorcerers.",
		Color = Color3.fromRGB(255, 205, 105),
	},
	{
		Min = 95,
		Max = 100,
		Name = "Complete Mastery",
		Short = "Complete",
		Description = "Your control is near the top of the jujutsu world.",
		Color = Color3.fromRGB(255, 105, 150),
	},
}

local TECHNIQUE_FLAVOR = {
	["Limitless"] = "You are learning to control space, distance, and cursed energy precision. Higher mastery improves defense, rescue choices, mission safety, and promotion pressure.",
	["Ten Shadows"] = "You are learning to command shadows, shikigami, and cursed space. Higher mastery improves scouting, rescue choices, and mission control.",
	["Blood Manipulation"] = "You are learning to weaponize blood without destroying your own body. Higher mastery improves risky mission choices and reduces the cost of dangerous actions.",
	["Cursed Speech"] = "You are learning to force cursed commands into reality. Higher mastery improves social pressure, mission control, and command-based choices.",
	["Boogie Woogie"] = "You are learning to control positioning and misdirection. Higher mastery improves escape choices, rescue choices, and impossible saves.",
	["Straw Doll"] = "You are learning to strike curses through links and residue. Higher mastery improves investigation, precision, and indirect exorcism choices.",
	["Ratio Technique"] = "You are learning to identify weak points under pressure. Higher mastery improves precision, smarter mission choices, and critical outcomes.",
	["Projection Sorcery"] = "You are learning to move through moments like frames. Higher mastery improves speed-based choices and clean mission execution.",
	["Idle Transfiguration"] = "You are learning to understand the shape of the soul. Higher mastery improves terrifying choices, curse analysis, and high-risk mission options.",
	["Disaster Flames"] = "You are learning to control destructive cursed flame. Higher mastery improves overwhelming force options and dangerous curse suppression.",
	["Thread Manipulation"] = "You are learning to bind, pull, and control targets from a distance. Higher mastery improves rescue and restraint options.",
	["Mirror Step"] = "You are learning to move through reflections and false openings. Higher mastery improves illusion-breaking and scouting choices.",
	["Grave Bloom"] = "You are learning to bury cursed energy through blooming death. Higher mastery improves exorcism, emotional resistance, and curse-cleansing choices.",
	["Static Binding"] = "You are learning to lock movement and disrupt energy through cursed static. Higher mastery improves containment and anti-recording choices.",
	["Glass Veil"] = "You are learning to bend visibility, reflection, and cursed perception. Higher mastery improves deception, escape, and concealment choices.",
	["Paper Shikigami"] = "You are learning to use paper constructs for scouting and support. Higher mastery improves tracking, surveillance, and indirect mission choices.",
	["Bone Forge"] = "You are learning to shape cursed bone into tools and weapons. Higher mastery improves cursed tool interactions and survival choices.",
	["Shadow Stitch"] = "You are learning to pin targets through their shadows. Higher mastery improves restraint, trap, and illusion-control choices.",
	["Echo Pulse"] = "You are learning to read cursed energy through sound and vibration. Higher mastery improves detection and investigation choices.",
	["Crow Funeral"] = "You are learning to use cursed birds, omen pressure, and swarm tactics. Higher mastery improves surveillance, intimidation, and mission disruption choices.",
	["Heavenly Restriction"] = "You do not rely on a normal cursed technique. Your body itself becomes the weapon. Higher mastery represents control, discipline, timing, and raw physical dominance.",
	["Shrine"] = "You are learning to turn slashes and cursed output into clean destruction. Higher mastery improves direct combat pressure and ruthless mission outcomes.",
	["Brain Transplant"] = "You are learning to preserve your will through stolen bodies and inherited memories. Higher mastery improves host control, combat stability, and forbidden relationship actions.",
	["Pumpkin Control"] = "You are learning to animate pumpkins, vines, and heavy seasonal constructs. Higher mastery improves field control, defense, and strange pressure-based outcomes.",
	["Copy"] = "You are learning to understand and reproduce cursed techniques. Higher mastery improves flexibility and special mission responses.",
	["Rika Manifestation"] = "You are learning to control overwhelming cursed presence. Higher mastery improves combat pressure and dangerous rescue outcomes.",
	["Cursed Spirit Manipulation"] = "You are learning to command curses as weapons. Higher mastery improves curse-control choices and mission domination.",
}

local TECHNIQUE_DESCRIPTION = {
	["Limitless"] = "A technique inherited through the Gojo bloodline that manipulates space at the atomic level. The user applies cursed energy to the concept of distance itself, generating infinite convergence that makes direct contact nearly impossible. At its peak, this technique produces an autonomous barrier around the user that deflects anything without conscious thought.",
	["Ten Shadows"] = "A technique that summons and controls up to ten shikigami through the medium of shadows. Each shikigami must be tamed through ritual combat before it can be commanded — a shikigami that defeats its user is lost forever. The technique's power scales with how many shikigami the user controls and how well each one has been mastered.",
	["Blood Manipulation"] = "A technique that grants complete control over one's own blood. The user can alter blood viscosity, temperature, and trajectory, weaponizing it externally or reinforcing the body from within. Skilled use can stop blood loss entirely, making the user nearly immune to conventional injury in a prolonged fight.",
	["Cursed Speech"] = "A technique that binds cursed energy to spoken commands, forcing reality to comply. The words themselves carry weight — a command delivered with sufficient force becomes physically unavoidable. The technique taxes the user's throat with every use, limiting how often commands can be issued before the body starts to break.",
	["Boogie Woogie"] = "A technique that swaps the position of anything that has been touched with cursed energy. Targets can include people, objects, or the user themselves. The swap is instantaneous and requires no wind-up, making it one of the most unpredictable close-range techniques in practical combat.",
	["Straw Doll"] = "A technique that creates cursed connections between the user's nails and a target, bypassing distance entirely. Attacks delivered to a nail or effigy transmit directly to the linked target. The connection persists as long as the cursed link remains active, making it effective against enemies who try to disengage.",
	["Ratio Technique"] = "A technique that divides anything the user touches into a ratio of ten parts. The point that falls on the precise boundary — the exact 6:4 split — becomes a guaranteed critical strike regardless of the target's defenses. Masters can identify this point on a moving target mid-combat.",
	["Projection Sorcery"] = "A technique that locks movement into a sequence of pre-planned frames. The user projects their next second of movement across 24 frozen frames, executing it at high speed. Any target caught in the projection is also locked into frames — and anything that doesn't follow a set path within that second is frozen for one second as a penalty.",
	["Idle Transfiguration"] = "A technique that reshapes the soul directly. The user can alter the form of any soul they make contact with, transforming humans into transfigured humans or manipulating their structure entirely. The resulting constructs obey no normal biological law and are controlled by the user at will.",
	["Disaster Flames"] = "A technique that generates and controls cursed flames of extreme heat and destructive output. The user can produce flames from their body without external fuel, directing them with precision or releasing them in wide-area bursts. The technique has a high CE cost per use but is among the most straightforwardly destructive in the jujutsu world.",
	["Thread Manipulation"] = "A technique that creates and controls threads of condensed cursed energy. The threads are invisible to those without cursed energy sensitivity and strong enough to cut through flesh and bone at sufficient mastery. The user can set threads in advance, binding spaces and creating invisible traps that trigger on contact.",
	["Mirror Step"] = "A technique that allows the user to enter and travel through reflective surfaces, emerging from any other reflective surface within range. At higher mastery, the user can pull targets into mirror-space and control what reflections show. The technique is nearly undetectable in environments with multiple reflective surfaces.",
	["Grave Bloom"] = "A technique that generates cursed flowers from accumulated death energy. The blooms absorb cursed energy from their surroundings and can be detonated, releasing the stored energy as a purifying blast. The technique is passive in accumulation but devastating in release.",
	["Static Binding"] = "A technique that generates cursed static — a field of disruptive energy that interferes with cursed technique output and motor control. Targets caught in the field find their technique activation delayed and their movements slightly desynchronized. At high mastery, the field can lock a target's technique entirely for a short window.",
	["Glass Veil"] = "A technique that bends light and cursed perception, making the user difficult to track visually or sense with cursed energy. The user does not become truly invisible — they become inconsistent, appearing in the wrong position or failing to register entirely for a split second. That gap is enough.",
	["Paper Shikigami"] = "A technique that animates paper constructs into functional shikigami. Each construct is single-use and limited in durability, but the technique allows the user to mass-produce scouts, decoys, and support units rapidly. Paper shikigami can carry messages, relay scouting data, or detonate on contact.",
	["Bone Forge"] = "A technique that hardens and shapes the user's own bone matter into weapons and tools. The extracted bone is denser than steel at peak output and can be regrown given enough cursed energy. The technique's biggest strength is speed — a weapon can be produced in under a second and replaced just as fast.",
	["Shadow Stitch"] = "A technique that anchors a target through their shadow, restricting movement as long as the shadow-link holds. If the target's shadow touches the user's or a surface the user has marked, the stitch can be applied from a distance. Breaking the stitch requires enough force to physically tear the cursed connection.",
	["Echo Pulse"] = "A technique that reads cursed energy through vibration and sound. The user can detect active techniques in a wide radius and distinguish their signatures, functioning as a living cursed energy scanner. At high mastery, the user can send a pulse that temporarily disrupts technique activation in a short radius.",
	["Crow Funeral"] = "A technique that controls cursed crows as scouting, combat, and intimidation instruments. The crows function as extensions of the user's senses and can apply cursed energy directly on contact. A large enough flock creates an oppressive presence that degrades enemy morale and blocks line of sight.",
	["Heavenly Restriction"] = "Not a cursed technique — an inborn contract that strips the body of cursed energy entirely in exchange for physical ability pushed beyond human limits. Speed, strength, and durability reach levels that rival or exceed cursed technique output. The restriction is permanent and cannot be undone.",
	["Shrine"] = "A technique that generates two intersecting slashes of pure cursed energy at all times, forming a cross-shaped zone of destruction the user can focus or release. The slashes cut through anything they contact regardless of conventional defense, making direct blocking ineffective. The technique's power scales directly with the user's cursed output.",
	["Brain Transplant"] = "A technique that allows the user to transfer their consciousness into a new host body through physical contact and cursed surgery. The technique preserves memories, skills, and cursed energy between transfers. Over time, the user can accumulate techniques from previous hosts, though full integration requires years of use in each body.",
	["Pumpkin Control"] = "A technique that animates pumpkins and seasonal plant matter with cursed energy, using them as constructs for combat, defense, and field control. The constructs are durable relative to their size and can absorb significant damage before breaking. The technique's ceiling is limited by how many constructs the user can maintain simultaneously.",
	["Copy"] = "A technique that records and reproduces cursed techniques the user has observed. The copied technique is always weaker than the original and degrades further with each copy-of-a-copy. The user can maintain a limited number of active copies at once, and each copy requires CE expenditure proportional to the original's complexity.",
	["Rika Manifestation"] = "A technique born from cursed love — a contract sealed in grief that bound the spirit of a deceased loved one to the user as an immense cursed spirit. The spirit's power dwarfs most conventional techniques, but control is imperfect. At lower mastery, the spirit acts on the user's emotion as much as their intent.",
	["Cursed Spirit Manipulation"] = "A technique that allows the user to consume and control cursed spirits, folding them into a personal army. Each consumed spirit retains its ability, which the user can then deploy. The technique requires actually defeating the spirit first — they cannot be captured at range. A skilled user maintains dozens of spirits simultaneously.",
}

local CE_TRAIT_DISPLAY = {
	lightning_ce     = { Label = "Lightning CE",      Color = Color3.fromRGB(245, 222, 60) },
	cursed_flame_ce  = { Label = "Cursed Flame CE",   Color = Color3.fromRGB(232, 82, 60) },
	infinity_pulse_ce= { Label = "Infinity Pulse CE", Color = Color3.fromRGB(118, 180, 255) },
	venom_ce         = { Label = "Venom CE",           Color = Color3.fromRGB(112, 236, 153) },
	serene_ce        = { Label = "Serene CE",          Color = Color3.fromRGB(174, 121, 255) },
	cursed_pressure_ce={ Label = "Cursed Pressure CE",Color = Color3.fromRGB(255, 207, 105) },
}

local BUTTON_SIZE = 18
local BUTTON_FIXED_X = 155
local BUTTON_RIGHT_PADDING = 2
local LABEL_GAP = 7

-- Helpers

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function setGradient(parent, colorA, colorB, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

local function getTechniqueName(stats)
	if not stats then return "None" end
	local ct = tostring(stats.CursedTechnique or "None")
	if ct == "None" or ct == "" then
		ct = tostring(stats.InnateTechnique or "None")
	end
	return ct
end

local function getMastery(stats)
	if not stats then return 0 end
	return math.clamp(math.floor(stats.TechniqueMastery or 0), 0, 100)
end

local function getMissionPowerBonus(mastery)
	return math.floor(mastery * 0.55)
end

local function getTechniqueFlavor(technique)
	return TECHNIQUE_FLAVOR[technique] or "Your cursed technique grows through training, assignments, pressure, and life events. Higher mastery improves mission power and can unlock better technique-specific choices."
end

local function getStageData(mastery)
	for _, data in ipairs(STAGE_DATA) do
		if mastery >= data.Min and mastery <= data.Max then
			return data
		end
	end
	return STAGE_DATA[1]
end

local function getNextStageData(mastery)
	for _, data in ipairs(STAGE_DATA) do
		if mastery < data.Min then
			return data
		end
	end
	return nil
end

local function makeButtonAnimation(button)
	local originalColor = button.BackgroundColor3
	local originalSize = button.Size

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(45, 35, 65),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = originalColor,
			Size = originalSize,
		}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.06), {
			Size = UDim2.new(
				originalSize.X.Scale,
				math.max(0, originalSize.X.Offset - 2),
				originalSize.Y.Scale,
				math.max(0, originalSize.Y.Offset - 2)
			),
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.06), {
			Size = originalSize,
		}):Play()
	end)
end

local function createLabel(parent, name, size, position, text, color, textSize, font, zIndex)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or THEME.Text
	label.TextSize = textSize or 14
	label.Font = font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.RichText = true
	label.Text = text or ""
	label.ZIndex = zIndex or 652
	label.Parent = parent
	return label
end

local function createCard(parent, name, size, position, zIndex)
	local card = Instance.new("Frame")
	card.Name = name
	card.Size = size
	card.Position = position
	card.BackgroundColor3 = THEME.Panel2
	card.BorderSizePixel = 0
	card.ZIndex = zIndex or 652
	card.Parent = parent
	addCorner(card, 12)
	addStroke(card, THEME.StrokeSoft, 1, 0.15)
	return card
end

-- ScreenGui

local gui = Instance.new("ScreenGui")
gui.Name = "BitKaisenTechniqueMasteryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 626
gui.Enabled = false
gui.Parent = playerGui

-- Overlay

local overlay = Instance.new("Frame")
overlay.Name = "TechniqueMasteryOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.38
overlay.ZIndex = 650
overlay.Parent = gui

-- Window

local window = Instance.new("Frame")
window.Name = "TechniqueMasteryWindow"
window.Size = UDim2.new(0, 620, 0, 540)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.52, 0)
window.BackgroundColor3 = THEME.Bg2
window.BorderSizePixel = 0
window.ZIndex = 651
window.Parent = overlay
addCorner(window, 18)
addStroke(window, THEME.PurpleSoft, 2, 0.05)
setGradient(window, Color3.fromRGB(19, 16, 30), Color3.fromRGB(9, 9, 15), 90)
responsiveScale.attach(window, 620, 540)

-- Header

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, -36, 0, 92)
header.Position = UDim2.new(0, 18, 0, 18)
header.BackgroundColor3 = THEME.Panel
header.BorderSizePixel = 0
header.ZIndex = 652
header.Parent = window
addCorner(header, 15)
addStroke(header, THEME.StrokeSoft, 1, 0.1)
setGradient(header, Color3.fromRGB(38, 26, 58), Color3.fromRGB(19, 19, 31), 0)

local headerAccent = Instance.new("Frame")
headerAccent.Name = "Accent"
headerAccent.Size = UDim2.new(0, 5, 1, -26)
headerAccent.Position = UDim2.new(0, 16, 0, 13)
headerAccent.BackgroundColor3 = THEME.Purple
headerAccent.BorderSizePixel = 0
headerAccent.ZIndex = 653
headerAccent.Parent = header
addCorner(headerAccent, 999)

local titleLabel = createLabel(
	header, "TitleLabel",
	UDim2.new(1, -130, 0, 28), UDim2.new(0, 34, 0, 14),
	"TECHNIQUE MASTERY", THEME.Text, 23, Enum.Font.GothamBlack, 653
)
titleLabel.TextWrapped = false
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

local subtitleLabel = createLabel(
	header, "SubtitleLabel",
	UDim2.new(1, -130, 0, 34), UDim2.new(0, 35, 0, 46),
	"Control, stage progress, mission power, and future unlocks.",
	THEME.SubText, 12, Enum.Font.GothamMedium, 653
)

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 38, 0, 38)
closeButton.Position = UDim2.new(1, -54, 0, 16)
closeButton.BackgroundColor3 = THEME.Panel3
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = THEME.Red
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.AutoButtonColor = false
closeButton.ZIndex = 654
closeButton.Parent = header
addCorner(closeButton, 10)
addStroke(closeButton, THEME.Stroke, 1, 0.2)
makeButtonAnimation(closeButton)

-- Content ScrollingFrame

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -36, 1, -128)
content.Position = UDim2.new(0, 18, 0, 122)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = THEME.PurpleSoft
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.ZIndex = 652
content.Parent = window

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingBottom = UDim.new(0, 14)
contentPadding.Parent = content

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
end)

-- Ability Card

local abilityCard = createCard(content, "AbilityCard", UDim2.new(1, -6, 0, 150), UDim2.new(0, 0, 0, 0), 653)
abilityCard.LayoutOrder = 1
setGradient(abilityCard, Color3.fromRGB(28, 22, 44), Color3.fromRGB(17, 17, 27), 0)

local abilityAccent = Instance.new("Frame")
abilityAccent.Name = "AbilityAccent"
abilityAccent.Size = UDim2.new(0, 5, 1, -26)
abilityAccent.Position = UDim2.new(0, 16, 0, 13)
abilityAccent.BackgroundColor3 = THEME.Purple
abilityAccent.BorderSizePixel = 0
abilityAccent.ZIndex = 654
abilityAccent.Parent = abilityCard
addCorner(abilityAccent, 999)

local techniqueNameLabel = createLabel(
	abilityCard, "TechniqueNameLabel",
	UDim2.new(1, -60, 0, 30), UDim2.new(0, 34, 0, 14),
	"EXPLOSIVE CE OUTPUT", THEME.Purple, 22, Enum.Font.GothamBlack, 654
)
techniqueNameLabel.TextWrapped = false
techniqueNameLabel.TextTruncate = Enum.TextTruncate.AtEnd

local ctInfoButton = Instance.new("TextButton")
ctInfoButton.Name = "CTInfoButton"
ctInfoButton.Size = UDim2.new(0, 24, 0, 24)
ctInfoButton.Position = UDim2.new(1, -36, 0, 17)
ctInfoButton.AnchorPoint = Vector2.new(0, 0)
ctInfoButton.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
ctInfoButton.BorderSizePixel = 0
ctInfoButton.TextColor3 = THEME.Purple
ctInfoButton.TextSize = 13
ctInfoButton.Font = Enum.Font.GothamBlack
ctInfoButton.Text = "?"
ctInfoButton.AutoButtonColor = false
ctInfoButton.ZIndex = 656
ctInfoButton.Parent = abilityCard
addCorner(ctInfoButton, 999)
addStroke(ctInfoButton, THEME.PurpleSoft, 1)
makeButtonAnimation(ctInfoButton)

-- Tag Row

local tagRow = Instance.new("Frame")
tagRow.Name = "TagRow"
tagRow.Size = UDim2.new(1, -68, 0, 28)
tagRow.Position = UDim2.new(0, 34, 0, 50)
tagRow.BackgroundTransparency = 1
tagRow.ZIndex = 654
tagRow.Parent = abilityCard

local tagLayout = Instance.new("UIListLayout")
tagLayout.FillDirection = Enum.FillDirection.Horizontal
tagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tagLayout.SortOrder = Enum.SortOrder.LayoutOrder
tagLayout.Padding = UDim.new(0, 8)
tagLayout.Parent = tagRow

local function makeInlineTag(name, text, color, width)
	local tag = Instance.new("TextLabel")
	tag.Name = name
	tag.Size = UDim2.new(0, width or 150, 0, 26)
	tag.BackgroundColor3 = Color3.fromRGB(32, 28, 46)
	tag.BorderSizePixel = 0
	tag.TextColor3 = color or THEME.Text
	tag.TextSize = 11
	tag.Font = Enum.Font.GothamBlack
	tag.Text = tostring(text or "")
	tag.ZIndex = 655
	tag.Parent = tagRow
	addCorner(tag, 999)
	addStroke(tag, color or THEME.Stroke, 1, 0.45)
	return tag
end

local stagePill = makeInlineTag("StagePill", "Elite Mastery", THEME.Purple, 158)
local powerPill = makeInlineTag("PowerPill", "+0 Mission Power", THEME.Green, 154)
local nextStageMiniLabel = makeInlineTag("NextStageMiniLabel", "2 needed", THEME.Gold, 92)

-- Mastery Bar

local barBack = Instance.new("Frame")
barBack.Name = "MasteryBarBack"
barBack.Size = UDim2.new(1, -68, 0, 24)
barBack.Position = UDim2.new(0, 34, 0, 90)
barBack.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
barBack.BorderSizePixel = 0
barBack.ZIndex = 654
barBack.Parent = abilityCard
addCorner(barBack, 999)
addStroke(barBack, THEME.Stroke, 1, 0.2)

local barFill = Instance.new("Frame")
barFill.Name = "MasteryBarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = THEME.Purple
barFill.BorderSizePixel = 0
barFill.ZIndex = 655
barFill.Parent = barBack
addCorner(barFill, 999)

local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "PercentLabel"
percentLabel.Size = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.TextColor3 = THEME.Text
percentLabel.TextSize = 13
percentLabel.Font = Enum.Font.GothamBlack
percentLabel.Text = "0 / 100"
percentLabel.ZIndex = 656
percentLabel.Parent = barBack

local nextStageLabel = createLabel(
	abilityCard, "NextStageLabel",
	UDim2.new(1, -68, 0, 22), UDim2.new(0, 34, 0, 121),
	"Next: Basic Control at 10 mastery",
	THEME.Gold, 12, Enum.Font.GothamBlack, 654
)
nextStageLabel.TextWrapped = false
nextStageLabel.TextTruncate = Enum.TextTruncate.AtEnd

-- Info Grid

local infoGrid = Instance.new("Frame")
infoGrid.Name = "InfoGrid"
infoGrid.Size = UDim2.new(1, -6, 0, 94)
infoGrid.BackgroundTransparency = 1
infoGrid.ZIndex = 653
infoGrid.LayoutOrder = 2
infoGrid.Parent = content

local infoGridLayout = Instance.new("UIGridLayout")
infoGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
infoGridLayout.CellSize = UDim2.new(0.5, -5, 1, 0)
infoGridLayout.Parent = infoGrid

local stageInfoCard = Instance.new("Frame")
stageInfoCard.Name = "StageInfoCard"
stageInfoCard.BackgroundColor3 = THEME.Panel2
stageInfoCard.BorderSizePixel = 0
stageInfoCard.ZIndex = 653
stageInfoCard.LayoutOrder = 1
stageInfoCard.Parent = infoGrid
addCorner(stageInfoCard, 12)
addStroke(stageInfoCard, THEME.StrokeSoft, 1, 0.15)

local stageTitle = createLabel(stageInfoCard, "StageTitle", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 10), "Current Stage", THEME.Text, 14, Enum.Font.GothamBlack, 654)
local stageDesc = createLabel(stageInfoCard, "StageDescription", UDim2.new(1, -28, 0, 50), UDim2.new(0, 14, 0, 34), "", THEME.SubText, 11, Enum.Font.GothamMedium, 654)
stageDesc.TextYAlignment = Enum.TextYAlignment.Top

local notesCard = Instance.new("Frame")
notesCard.Name = "TechniqueNotesCard"
notesCard.BackgroundColor3 = THEME.Panel2
notesCard.BorderSizePixel = 0
notesCard.ZIndex = 653
notesCard.LayoutOrder = 2
notesCard.Parent = infoGrid
addCorner(notesCard, 12)
addStroke(notesCard, THEME.StrokeSoft, 1, 0.15)

local flavorTitle = createLabel(notesCard, "FlavorTitle", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 10), "Technique Notes", THEME.Text, 14, Enum.Font.GothamBlack, 654)
local flavorText = createLabel(notesCard, "FlavorText", UDim2.new(1, -28, 0, 50), UDim2.new(0, 14, 0, 34), "", THEME.SubText, 11, Enum.Font.GothamMedium, 654)
flavorText.TextYAlignment = Enum.TextYAlignment.Top

-- Timeline Card

local timelineCard = createCard(content, "TimelineCard", UDim2.new(1, -6, 0, 210), UDim2.new(0, 0, 0, 0), 653)
timelineCard.LayoutOrder = 4

local timelineTitle = createLabel(timelineCard, "TimelineTitle", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 12), "Mastery Timeline", THEME.Text, 16, Enum.Font.GothamBlack, 654)

local timelineLine = Instance.new("Frame")
timelineLine.Name = "TimelineLine"
timelineLine.Size = UDim2.new(0, 3, 0, 142)
timelineLine.Position = UDim2.new(0, 29, 0, 48)
timelineLine.BackgroundColor3 = THEME.Stroke
timelineLine.BorderSizePixel = 0
timelineLine.ZIndex = 654
timelineLine.Parent = timelineCard
addCorner(timelineLine, 999)

local timelineFill = Instance.new("Frame")
timelineFill.Name = "TimelineFill"
timelineFill.Size = UDim2.new(1, 0, 0, 0)
timelineFill.Position = UDim2.new(0, 0, 0, 0)
timelineFill.BackgroundColor3 = THEME.Purple
timelineFill.BorderSizePixel = 0
timelineFill.ZIndex = 655
timelineFill.Parent = timelineLine
addCorner(timelineFill, 999)

local timelineItems = {}

local timelineData = {
	{ Value = 0, Label = "Dormant", Note = "Technique barely awakened" },
	{ Value = 10, Label = "Basic", Note = "stable enough to use" },
	{ Value = 25, Label = "Refined", Note = "mission choices improve" },
	{ Value = 50, Label = "Advanced", Note = "stronger CT applications" },
	{ Value = 75, Label = "Elite", Note = "high-level pressure" },
	{ Value = 95, Label = "Domain Path", Note = "future domain unlock path" },
}

for index, data in ipairs(timelineData) do
	local y = 44 + ((index - 1) * 28)

	local node = Instance.new("Frame")
	node.Name = "TimelineNode" .. tostring(index)
	node.Size = UDim2.new(0, 14, 0, 14)
	node.Position = UDim2.new(0, 23, 0, y)
	node.BackgroundColor3 = THEME.Muted
	node.BorderSizePixel = 0
	node.ZIndex = 656
	node.Parent = timelineCard
	addCorner(node, 999)
	addStroke(node, THEME.Stroke, 1, 0.15)

	local valueLabel = createLabel(
		timelineCard, "TimelineValue" .. tostring(index),
		UDim2.new(0, 42, 0, 22), UDim2.new(0, 48, 0, y - 4),
		tostring(data.Value) .. "+", THEME.Muted, 12, Enum.Font.GothamBlack, 656
	)
	valueLabel.TextWrapped = false

	local label = createLabel(
		timelineCard, "TimelineLabel" .. tostring(index),
		UDim2.new(1, -160, 0, 22), UDim2.new(0, 90, 0, y - 4),
		data.Label, THEME.SubText, 13, Enum.Font.GothamBlack, 656
	)
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.AtEnd

	local note = createLabel(
		timelineCard, "TimelineNote" .. tostring(index),
		UDim2.new(0, 170, 0, 22), UDim2.new(1, -185, 0, y - 4),
		data.Note, THEME.Muted, 11, Enum.Font.GothamMedium, 656
	)
	note.TextWrapped = false
	note.TextTruncate = Enum.TextTruncate.AtEnd

	table.insert(timelineItems, {
		Value = data.Value,
		Node = node,
		ValueLabel = valueLabel,
		Label = label,
		Note = note,
	})
end

-- Responsive helpers

local function isTimelineMobile()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return viewport.X < 760
end

local function applyTimelineResponsiveLayout()
	local mobile = isTimelineMobile()

	if mobile then
		timelineCard.Size = UDim2.new(1, -6, 0, 270)
		timelineLine.Size = UDim2.new(0, 3, 0, 196)
		timelineLine.Position = UDim2.new(0, 29, 0, 50)
	else
		timelineCard.Size = UDim2.new(1, -6, 0, 210)
		timelineLine.Size = UDim2.new(0, 3, 0, 142)
		timelineLine.Position = UDim2.new(0, 29, 0, 48)
	end

	for index, item in ipairs(timelineItems) do
		local y = mobile and (50 + ((index - 1) * 33)) or (44 + ((index - 1) * 28))
		item.Node.Position = UDim2.new(0, 23, 0, y)
		item.ValueLabel.Position = UDim2.new(0, 48, 0, y - 4)
		item.ValueLabel.Size = UDim2.new(0, mobile and 40 or 42, 0, 22)
		item.Label.Position = UDim2.new(0, mobile and 98 or 90, 0, y - 7)
		item.Label.Size = mobile and UDim2.new(1, -116, 0, 18) or UDim2.new(1, -160, 0, 22)
		item.Label.TextSize = mobile and 12 or 13
		item.Note.Position = mobile and UDim2.new(0, 98, 0, y + 10) or UDim2.new(1, -185, 0, y - 4)
		item.Note.Size = mobile and UDim2.new(1, -116, 0, 18) or UDim2.new(0, 170, 0, 22)
		item.Note.TextSize = mobile and 9 or 11
		item.Note.TextWrapped = mobile
		item.Note.TextTruncate = mobile and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
	end
end

local function updateMilestones(mastery)
	applyTimelineResponsiveLayout()
	local maxTimelineHeight = isTimelineMobile() and 196 or 142
	local fillRatio = math.clamp(mastery / 95, 0, 1)
	TweenService:Create(timelineFill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, math.floor(maxTimelineHeight * fillRatio)),
	}):Play()

	for _, item in ipairs(timelineItems) do
		local unlocked = mastery >= item.Value
		item.Node.BackgroundColor3 = unlocked and THEME.Purple or THEME.Muted
		item.ValueLabel.TextColor3 = unlocked and THEME.Gold or THEME.Muted
		item.Label.TextColor3 = unlocked and THEME.Text or THEME.SubText
		item.Note.TextColor3 = unlocked and THEME.SubText or THEME.Muted
	end
end

local function refresh()
	local stats = currentStats or playerState.stats()
	if not stats then stats = {} end

	local technique = getTechniqueName(stats)
	local mastery = getMastery(stats)
	local stage = getStageData(mastery)
	local nextData = getNextStageData(mastery)
	local powerBonus = getMissionPowerBonus(mastery)

	techniqueNameLabel.Text = string.upper(technique)
	stagePill.Text = stage.Name
	stagePill.TextColor3 = THEME.Text
	stagePill.BackgroundColor3 = THEME.PurpleDark
	powerPill.Text = "+" .. tostring(powerBonus) .. " Mission Power"
	percentLabel.Text = tostring(mastery) .. " / 100"

	stageTitle.Text = "Current Stage: " .. stage.Name
	stageDesc.Text = stage.Description

	if nextData then
		local needed = math.max(0, nextData.Min - mastery)
		nextStageMiniLabel.Text = tostring(needed) .. " needed"
		nextStageLabel.Text = "Next: " .. nextData.Name .. " at " .. tostring(nextData.Min) .. " mastery"
	else
		nextStageMiniLabel.Text = _mas("complete", "Complete")
		nextStageLabel.Text = _mas("complete_cap", "Complete: you have reached the current mastery cap.")
	end

	if technique == "None" then
		flavorText.Text = _mas("no_technique", "You have not awakened an innate cursed technique yet. Age up, train cursed energy, and survive long enough for your cursed energy to take shape.")
	else
		local effectNote = BitKaisenTechniqueEffects.GetTechniqueNote(stats)
		flavorText.Text = getTechniqueFlavor(technique) .. (effectNote ~= "" and ("\n\nCombat effect: " .. effectNote) or "")
	end

	updateMilestones(mastery)

	TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(mastery / 100, 0, 1, 0),
		BackgroundColor3 = stage.Color,
	}):Play()
end

-- CT Info Modal

local infoModal = Instance.new("Frame")
infoModal.Name = "CTInfoModal"
infoModal.Size = UDim2.new(1, -24, 1, -24)
infoModal.Position = UDim2.new(0, 12, 0, 12)
infoModal.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
infoModal.BorderSizePixel = 0
infoModal.ZIndex = 700
infoModal.Visible = false
infoModal.Parent = window
addCorner(infoModal, 14)
addStroke(infoModal, THEME.PurpleSoft, 1, 0.1)

local infoAccent = Instance.new("Frame")
infoAccent.Name = "Accent"
infoAccent.Size = UDim2.new(1, 0, 0, 4)
infoAccent.Position = UDim2.new(0, 0, 0, 0)
infoAccent.BackgroundColor3 = THEME.Purple
infoAccent.BorderSizePixel = 0
infoAccent.ZIndex = 701
infoAccent.Parent = infoModal
addCorner(infoAccent, 999)
setGradient(infoAccent, THEME.Purple, THEME.Blue, 0)

local infoCloseBtn = Instance.new("TextButton")
infoCloseBtn.Name = "CloseBtn"
infoCloseBtn.Size = UDim2.new(0, 28, 0, 28)
infoCloseBtn.Position = UDim2.new(1, -38, 0, 12)
infoCloseBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
infoCloseBtn.BorderSizePixel = 0
infoCloseBtn.TextColor3 = THEME.SubText
infoCloseBtn.TextSize = 14
infoCloseBtn.Font = Enum.Font.GothamBlack
infoCloseBtn.Text = "✕"
infoCloseBtn.AutoButtonColor = false
infoCloseBtn.ZIndex = 702
infoCloseBtn.Parent = infoModal
addCorner(infoCloseBtn, 999)
makeButtonAnimation(infoCloseBtn)

local infoTechName = createLabel(
	infoModal, "TechName",
	UDim2.new(1, -80, 0, 32), UDim2.new(0, 20, 0, 14),
	"", THEME.Purple, 20, Enum.Font.GothamBlack, 701
)
infoTechName.TextWrapped = false
infoTechName.TextTruncate = Enum.TextTruncate.AtEnd

local infoDivider = Instance.new("Frame")
infoDivider.Name = "Divider"
infoDivider.Size = UDim2.new(1, -40, 0, 1)
infoDivider.Position = UDim2.new(0, 20, 0, 52)
infoDivider.BackgroundColor3 = THEME.StrokeSoft
infoDivider.BorderSizePixel = 0
infoDivider.ZIndex = 701
infoDivider.Parent = infoModal

local infoDescLabel = createLabel(
	infoModal, "Description",
	UDim2.new(1, -40, 0, 120), UDim2.new(0, 20, 0, 62),
	"", THEME.SubText, 12, Enum.Font.GothamMedium, 701
)
infoDescLabel.TextWrapped = true
infoDescLabel.TextYAlignment = Enum.TextYAlignment.Top

local infoTraitRow = Instance.new("Frame")
infoTraitRow.Name = "TraitRow"
infoTraitRow.Size = UDim2.new(1, -40, 0, 28)
infoTraitRow.Position = UDim2.new(0, 20, 0, 192)
infoTraitRow.BackgroundTransparency = 1
infoTraitRow.ZIndex = 701
infoTraitRow.Parent = infoModal

local infoTraitIcon = createLabel(infoTraitRow, "Icon", UDim2.new(0, 80, 1, 0), UDim2.new(0, 0, 0, 0), "CE TRAIT", THEME.Muted, 10, Enum.Font.GothamBlack, 702)
local infoTraitValue = createLabel(infoTraitRow, "Value", UDim2.new(1, -88, 1, 0), UDim2.new(0, 88, 0, 0), "None", THEME.Text, 12, Enum.Font.GothamBold, 702)

local infoAwakeRow = Instance.new("Frame")
infoAwakeRow.Name = "AwakeRow"
infoAwakeRow.Size = UDim2.new(1, -40, 0, 28)
infoAwakeRow.Position = UDim2.new(0, 20, 0, 226)
infoAwakeRow.BackgroundTransparency = 1
infoAwakeRow.ZIndex = 701
infoAwakeRow.Parent = infoModal

local infoAwakeIcon = createLabel(infoAwakeRow, "Icon", UDim2.new(0, 80, 1, 0), UDim2.new(0, 0, 0, 0), "AWAKENING", THEME.Muted, 10, Enum.Font.GothamBlack, 702)
local infoAwakeValue = createLabel(infoAwakeRow, "Value", UDim2.new(1, -88, 1, 0), UDim2.new(0, 88, 0, 0), "Not yet", THEME.Text, 12, Enum.Font.GothamBold, 702)

local infoIsOpen = false

local function openInfoModal()
	if infoIsOpen then return end
	infoIsOpen = true
	local stats = currentStats or playerState.stats() or {}
	local technique = getTechniqueName(stats)

	infoTechName.Text = string.upper(technique == "None" and "No Technique" or technique)

	local desc = TECHNIQUE_DESCRIPTION[technique]
	if desc then
		infoDescLabel.Text = desc
	elseif technique == "None" then
		infoDescLabel.Text = "Your cursed technique has not manifested yet. Train your cursed energy, survive long enough, and it will take shape on its own."
	else
		infoDescLabel.Text = "Description not yet available."
	end

	local traitId = tostring(stats.CETrait or "")
	local traitData = CE_TRAIT_DISPLAY[traitId]
	if traitData then
		infoTraitValue.Text = traitData.Label
		infoTraitValue.TextColor3 = traitData.Color
	else
		infoTraitValue.Text = "None"
		infoTraitValue.TextColor3 = THEME.Muted
	end

	if stats.AwakeningTriggered == true then
		local ctx = tostring(stats.AwakeningContext or "")
		local ctxLabel = ctx == "near_death" and "Near-death" or ctx == "domain_loss" and "Domain loss" or ctx == "mission_survive" and "Mission survival" or ctx == "age_threshold" and "Age threshold" or "Triggered"
		infoAwakeValue.Text = "Triggered — " .. ctxLabel
		infoAwakeValue.TextColor3 = THEME.Purple
	elseif stats.AwakeningEligible == true then
		infoAwakeValue.Text = "Eligible — conditions not yet met"
		infoAwakeValue.TextColor3 = THEME.Gold
	else
		infoAwakeValue.Text = "Not applicable"
		infoAwakeValue.TextColor3 = THEME.Muted
	end

	infoModal.Visible = true
	infoModal.BackgroundTransparency = 1
	TweenService:Create(infoModal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()
end

local function closeInfoModal()
	if not infoIsOpen then return end
	infoIsOpen = false
	TweenService:Create(infoModal, TweenInfo.new(0.14), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.15, function()
		if not infoIsOpen then
			infoModal.Visible = false
		end
	end)
end

ctInfoButton.MouseButton1Click:Connect(openInfoModal)
infoCloseBtn.MouseButton1Click:Connect(closeInfoModal)

-- Open / Close

local function openPanel()
	if isOpen then return end
	isOpen = true

	refresh()

	gui.Enabled = true
	overlay.BackgroundTransparency = 1
	window.BackgroundTransparency = 1
	window.Position = UDim2.new(0.5, 0, 0.55, 0)

	TweenService:Create(overlay, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.38,
	}):Play()

	TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.52, 0),
	}):Play()
end

local function closePanel()
	if not isOpen then return end
	isOpen = false

	closeInfoModal()

	TweenService:Create(overlay, TweenInfo.new(0.18), {
		BackgroundTransparency = 1,
	}):Play()

	TweenService:Create(window, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.55, 0),
	}):Play()

	task.delay(0.2, function()
		if not isOpen then
			gui.Enabled = false
		end
	end)
end

closeButton.MouseButton1Click:Connect(function()
	uiState.closeRoute()
end)

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.Position then
			local absPos = window.AbsolutePosition
			local absSize = window.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x < absPos.X or x > absPos.X + absSize.X or y < absPos.Y or y > absPos.Y + absSize.Y then
				uiState.closeRoute()
			end
		end
	end
end)

-- Profile card "?" button (MasteryButtonController logic)

local function setupProfileButton()
	local bitKaisenGui = playerGui:FindFirstChild("BitKaisenGui")
	if not bitKaisenGui then return end

	local mainPanel = bitKaisenGui:FindFirstChild("MainPanel")
	if not mainPanel then return end

	local profileCard = mainPanel:FindFirstChild("ProfileCard")
	if not profileCard then return end

	local profileScroll = profileCard:FindFirstChild("ProfileScroll")
	if not profileScroll then return end

	local techniqueRow = profileScroll:FindFirstChild("TechniqueRow")
	if not techniqueRow then return end

	local function findTechniqueLabel()
		local directLabel = techniqueRow:FindFirstChild("TechniqueLabel")
		if directLabel and directLabel:IsA("TextLabel") then
			return directLabel
		end
		for _, descendant in ipairs(techniqueRow:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				local text = tostring(descendant.Text or "")
				if string.sub(text, 1, #"Technique:") == "Technique:" then
					return descendant
				end
			end
		end
		return nil
	end

	local techLabel = findTechniqueLabel()

	local oldButton = profileCard:FindFirstChild("TechniqueMasteryHelpButton", true)
	if oldButton then oldButton:Destroy() end

	local helpButton = Instance.new("TextButton")
	helpButton.Name = "TechniqueMasteryHelpButton"
	helpButton.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
	helpButton.AnchorPoint = Vector2.new(0, 0.5)
	helpButton.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
	helpButton.BorderSizePixel = 0
	helpButton.TextColor3 = Color3.fromRGB(205, 170, 255)
	helpButton.TextSize = 12
	helpButton.Font = Enum.Font.GothamBlack
	helpButton.Text = "?"
	helpButton.AutoButtonColor = false
	helpButton.ZIndex = 50
	helpButton.Parent = techniqueRow
	addCorner(helpButton, 999)
	addStroke(helpButton, Color3.fromRGB(95, 55, 150), 1)
	makeButtonAnimation(helpButton)

	helpButton.MouseButton1Click:Connect(function()
		uiState.navigate(ROUTE)
	end)

	local function layoutButton()
		if not helpButton or not helpButton.Parent then return end
		if not techniqueRow or not techniqueRow.Parent then return end

		local rowWidth = techniqueRow.AbsoluteSize.X
		if rowWidth <= 0 then rowWidth = profileCard.AbsoluteSize.X end

		local maxX = math.max(0, rowWidth - BUTTON_SIZE - BUTTON_RIGHT_PADDING)
		local pinnedX = math.clamp(BUTTON_FIXED_X, 0, maxX)

		techniqueRow.ClipsDescendants = false

		if techLabel and techLabel.Parent then
			techLabel.Position = UDim2.new(0, 0, 0, 0)
			techLabel.Size = UDim2.new(0, math.max(30, pinnedX - LABEL_GAP), 1, 0)
			techLabel.TextWrapped = false
			techLabel.TextTruncate = Enum.TextTruncate.AtEnd
			techLabel.TextXAlignment = Enum.TextXAlignment.Left
			techLabel.TextYAlignment = Enum.TextYAlignment.Center
		end

		helpButton.AnchorPoint = Vector2.new(0, 0.5)
		helpButton.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		helpButton.Position = UDim2.new(0, pinnedX, 0.5, 0)
		helpButton.Visible = true
	end

	layoutButton()

	techniqueRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(layoutButton)
	end)

	profileCard:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(layoutButton)
	end)

	task.delay(0.1, layoutButton)
	task.delay(0.5, layoutButton)
end

-- Init

local function init()
	uiState.subscribe(function(route)
		if route == ROUTE then
			openPanel()
		else
			if isOpen then closePanel() end
		end
	end)

	local ule = remotes.updateLifeEvent()
	if ule then
		ule.OnClientEvent:Connect(function(updatedStats)
			if typeof(updatedStats) == "table" then
				currentStats = updatedStats
				if isOpen then refresh() end
			end
		end)
	end

	task.defer(function()
		task.wait(0.5)
		setupProfileButton()
	end)
end

return { init = init, open = function() uiState.navigate(ROUTE) end }
