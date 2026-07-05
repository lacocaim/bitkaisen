-- Shared step list for the onboarding tutorial (Fase 2), consumed by BOTH
-- FirstTimeGuidancePanel.luau (PC) and MobileFirstTimeGuidancePanel.luau
-- (Mobile) so the copy and category coverage never drift between platforms.
-- Localization lives here too (one place to translate, not two) -- each step
-- resolves through the game's existing locale system (same `tOrFallback`
-- pattern already used by ProfileCard.luau/the old 4-step guidance).
--
-- Per-step fields:
--   Title, Body, Button -- already resolved display strings (localized)
--   TargetPath   -- name of a direct child of MainPanel to highlight (PC-style)
--   NavId        -- navRegistry category id; each platform resolves this to
--                   its own nav button naming convention
--   TargetGlobalPath -- dot-path resolved from PlayerGui root (e.g. the
--                   native topbar), for targets outside the dashboard
--   TargetIconGroup -- highlights all 7 of our TopbarPlus icons (Help&Guide,
--                   free rewards, settings, etc.) together as one tight box,
--                   via a proxy Frame sized to their real bounding box (see
--                   resolveTarget). The actual bug that made this look
--                   broken all session wasn't the icon-grouping math (that
--                   was correct) -- it was a missing GuiInset correction in
--                   FocusHighlight.luau's own overlay layer, which put the
--                   border ~58px away from the real icons regardless of how
--                   the target box was computed.
--   CardSide -- "right" pins the tutorial's own info card to the right edge
--                   of the screen instead of the usual top/bottom
--                   auto-placement, for steps whose target (e.g.
--                   LogContainer) fills most of the screen and would
--                   otherwise sit under the card.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local navRegistry = require("@ui-state/navRegistry")

local BitKaisenLocale = require(ReplicatedStorage:WaitForChild("locale"))
local _L = BitKaisenLocale.getClientLocale()
local function _g(key: string, fallback: string): string
	return BitKaisenLocale.tOrFallback(_L, "guidance." .. key, nil, fallback)
end

-- Keyed by the same ids used in navRegistry.register() (see
-- BitKaisenClient/BitKaisenMobileClient) so the step list always matches
-- whatever categories actually exist -- no step for a removed category, no
-- missing step for a new one.
local CATEGORY_KEYS = {
	weekly = "weekly",
	missions = "missions",
	activities = "activities",
	relationships = "relationships",
	assets = "assets",
	jobs = "jobs",
	affiliations = "affiliations",
	domain = "domain",
	rivals = "rivals",
	history = "history",
	mentor = "mentor",
	binding_vows = "binding_vows",
	technique_mastery = "technique_mastery",
}

local CATEGORY_FALLBACK = {
	weekly = { Title = "Weekly Challenges", Body = "Complete weekly goals for bonus money, CE, and mastery." },
	missions = { Title = "Missions", Body = "Take on jobs from the Jujutsu Society for money, reputation, and rank progress." },
	activities = { Title = "Activities", Body = "Spend your six months here: train, rest, work, or take risks. You only get a few actions per age -- the counter shows how many are left." },
	relationships = { Title = "Relationships", Body = "Family, friends, and rivals age alongside you. Spend time to build trust, train together, or recruit them." },
	assets = { Title = "Assets", Body = "Manage property and cursed tools you own or can inherit." },
	jobs = { Title = "Jobs", Body = "Work civilian or sorcerer jobs for steady income." },
	affiliations = { Title = "Affiliations", Body = "Jujutsu High, clans, and organizations you can join, represent, or lead." },
	domain = { Title = "Domain Expansion", Body = "Unlock and master your Domain through advanced training." },
	rivals = { Title = "Rivals", Body = "Track reputation and rivalries with other sorcerers." },
	history = { Title = "World History", Body = "See how the world changes around you as eras, wars, and rankings shift." },
	mentor = { Title = "Mentor", Body = "Once you qualify, become a Jujutsu Mentor and teach the next generation." },
	binding_vows = { Title = "Binding Vows", Body = "Trade a real sacrifice for real power through a Binding Vow." },
	technique_mastery = { Title = "Technique Mastery", Body = "Train your cursed technique, awaken Haki-like traits, and prepare your Domain." },
}

local function buildCategorySteps()
	local steps = {}
	for _, entry in navRegistry.getEntries() do
		local keyBase = CATEGORY_KEYS[entry.id]
		local fallback = CATEGORY_FALLBACK[entry.id]
		local title = keyBase and _g("cat_" .. keyBase .. "_title", fallback and fallback.Title or entry.label)
			or entry.label
		local body = keyBase
				and _g("cat_" .. keyBase .. "_body", fallback and fallback.Body or ("Check out " .. entry.label .. "."))
			or ("Check out " .. entry.label .. ".")
		table.insert(steps, {
			Title = title,
			Body = body,
			Button = _g("btn_next", "NEXT"),
			NavId = entry.id,
		})
	end
	return steps
end

local function buildSteps()
	local steps = {
		{
			Title = _g("step1_title", "Welcome to BitKaisen"),
			Body = _g("step1_body", "Age up, make choices, and build your cursed legacy."),
			Button = _g("btn_next", "NEXT"),
		},
		{
			Title = _g("step2_title", "Use + AGE"),
			Body = _g("step2_body", "Aging moves your life forward six months at a time. Some years are quiet, others trigger events, missions, or relationships."),
			Button = _g("btn_next", "NEXT"),
			TargetPath = "ActionRow",
		},
		{
			Title = _g("step3_title", "Your Story So Far"),
			Body = _g("step3_body", "Every birth, event, fight, illness, and milestone gets written here as you age. Read it to follow your journey."),
			Button = _g("btn_next", "NEXT"),
			TargetPath = "LogContainer",
			-- LogContainer fills most of the screen, so the usual top/bottom
			-- auto-placement always ends up sitting on top of its own text.
			-- Pin the card to the right edge instead, just for this step.
			CardSide = "right",
		},
		{
			Title = _g("step4_title", "This Is You"),
			Body = _g("step4_body", "Your rank, technique, cursed energy, money, reputation, and rank progress all live here."),
			Button = _g("btn_next", "NEXT"),
			TargetPath = "ProfileCard",
		},
		{
			Title = _g("step5_title", "Quick Access"),
			Body = _g("step5_body", "Up here: Help & Guide, free rewards, settings, and other quick actions -- always one click away."),
			Button = _g("btn_next", "NEXT"),
			TargetIconGroup = true,
		},
	}

	for _, step in buildCategorySteps() do
		table.insert(steps, step)
	end

	table.insert(steps, {
		Title = _g("step_win_title", "How To Win"),
		Body = _g("step_win_body", "Climb the ranks, master your technique, and build a legacy that outlives you. When you die, your heir continues the story, a little stronger than you started."),
		Button = _g("btn_next", "NEXT"),
	})
	table.insert(steps, {
		Title = _g("step_finish_title", "Now Go Live Your Legacy!"),
		Body = _g("step_finish_body", "Close this and press + AGE to begin. Your story is waiting."),
		Button = _g("btn_done", "FINISH"),
	})

	return steps
end

return { buildSteps = buildSteps }
