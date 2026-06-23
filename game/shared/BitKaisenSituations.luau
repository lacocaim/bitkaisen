-- ModuleScript: BitKaisenSituations
-- Location: ReplicatedStorage
--
-- Purpose:
-- Handles mission situation events and filters which choices the player can take.
--
-- Supports:
-- RequiresTechnique = true
-- RequiresSpecificTechnique = "Limitless"
-- RequiresSmarts = 50
-- ForceSuccess = true
-- ForceFail = true

local BitKaisenSituations = {}
local BitKaisenStats = require(game:GetService("ReplicatedStorage"):WaitForChild("BitKaisenStats"))

local GRADE_ORDER = {
	["Grade 4"] = 1,
	["Semi-Grade 3"] = 2,
	["Grade 3"] = 3,
	["Semi-Grade 2"] = 4,
	["Grade 2"] = 5,
	["Semi-Grade 1"] = 6,
	["Grade 1"] = 7,
	["Special Grade 1"] = 8,
	["Special Grade"] = 9
}

BitKaisenSituations.Database = {
	{
		Id = "civilian_thrown_with_baby",
		Title = "Caught Between Lives",
		Body = "While protecting a baby you pulled from the wreckage, a curse picks up a screaming civilian and hurls them straight at you. You have a heartbeat to react.",
		Options = {
			{
				Text = "Set the baby down, catch the adult",
				Description = "You set the baby down behind you and caught the adult. The adult lived. The baby was uninjured, but cried for hours.",
				Effects = { Reputation = 4, Happiness = -3 },
				PowerBonus = -5
			},
			{
				Text = "Shield both with your body",
				Description = "You took the impact yourself, shielding the baby and bracing for the adult. Both lived. You did not walk away the same.",
				Effects = { Reputation = 12, Health = -22, Happiness = 5 },
				PowerBonus = -15
			},
			{
				Text = "Use your cursed technique to redirect the adult",
				Description = "You activated your cursed technique mid-air and steered the adult into a softer angle. Everyone survived. The curse noticed your skill.",
				Effects = { Reputation = 10, CursedEnergy = -8, Happiness = 3 },
				PowerBonus = 0,
				RequiresTechnique = true
			},

			-- Technique-specific choices
			{
				Text = "[Limitless] Stop the impact before it reaches you",
				Description = "Infinity caught the adult before the collision could fully happen. The baby stayed safe, the civilian survived, and everyone watching understood why your technique was feared.",
				Effects = { Reputation = 16, CursedEnergy = -14, Happiness = 4 },
				PowerBonus = 12,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Ten Shadows] Send a shikigami to intercept",
				Description = "A shikigami burst from the shadows and intercepted the civilian mid-flight. The impact was ugly, but controlled. Both lives stayed intact.",
				Effects = { Reputation = 13, CursedEnergy = -10, Happiness = 3 },
				PowerBonus = 8,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Blood Manipulation] Pull them aside with blood threads",
				Description = "You cut your palm and snapped blood threads around the civilian, dragging them away from the collision. It worked, but your body felt the cost.",
				Effects = { Reputation = 12, Health = -6, CursedEnergy = -7, Happiness = 2 },
				PowerBonus = 7,
				RequiresSpecificTechnique = "Blood Manipulation"
			},
			{
				Text = "[Cursed Speech] Command the curse to stop",
				Description = "Your command tore through the air. The curse froze long enough for you to move both civilians away from danger.",
				Effects = { Reputation = 14, CursedEnergy = -12, Happiness = 3 },
				PowerBonus = 9,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Boogie Woogie] Swap the civilian out of danger",
				Description = "You clapped once. The civilian switched places with loose debris, and the curse's own throw missed its mark.",
				Effects = { Reputation = 13, CursedEnergy = -9, Happiness = 2 },
				PowerBonus = 10,
				RequiresSpecificTechnique = "Boogie Woogie"
			},
			{
				Text = "[Projection Sorcery] Move before anyone can react",
				Description = "You moved through the moment like a sequence of frames, reaching the civilian before the curse could finish the throw.",
				Effects = { Reputation = 13, CursedEnergy = -10, Happiness = 2 },
				PowerBonus = 9,
				RequiresSpecificTechnique = "Projection Sorcery"
			},

			{
				Text = "Dodge and let them hit the wall",
				Description = "You sidestepped. The civilian hit the wall and stopped moving. You held the baby tight and finished the curse without distraction.",
				Effects = { Reputation = -18, Happiness = -15 },
				PowerBonus = 12
			}
		}
	},

	{
		Id = "possessed_civilian",
		Title = "Wearing Someone's Face",
		Body = "A civilian charges you with no hesitation, eyes wrong. Their cursed energy signature is fresh. The host might still be in there somewhere.",
		Options = {
			{
				Text = "Knock them out, save the host",
				Description = "You held back, hit a pressure point, and dropped them clean. The curse evacuated the body. The host survived, shaken.",
				Effects = { Reputation = 8, Happiness = 2 },
				PowerBonus = -10
			},
			{
				Text = "Kill them, finish the curse fast",
				Description = "You did not hold back. The host died. The curse died with them. Cleaner, faster, harder to explain in the report.",
				Effects = { Reputation = -12, Happiness = -10 },
				PowerBonus = 8
			},
			{
				Text = "Read the binding and exorcise cleanly",
				Description = "You studied the curse's grip on the host and broke it without violence. The host woke up confused. You earned a quiet kind of respect.",
				Effects = { Reputation = 15, Smarts = 3 },
				PowerBonus = -8,
				RequiresSmarts = 50
			},

			-- Technique-specific choices
			{
				Text = "[Idle Transfiguration] Separate curse from host tissue",
				Description = "You touched the host and reshaped the boundary between flesh and curse. The host survived, but everyone around you looked disturbed.",
				Effects = { Reputation = 10, Happiness = -6, CursedEnergy = -14 },
				PowerBonus = 16,
				RequiresSpecificTechnique = "Idle Transfiguration"
			},
			{
				Text = "[Cursed Speech] Command the host to sleep",
				Description = "You forced a command into the host's body. They collapsed instantly, giving you enough time to purge the curse's control.",
				Effects = { Reputation = 13, CursedEnergy = -12, Happiness = 2 },
				PowerBonus = 10,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Ratio Technique] Strike the exact weak point",
				Description = "You calculated the cleanest point to strike and separated the curse's hold without destroying the host.",
				Effects = { Reputation = 12, Smarts = 2, Happiness = 2 },
				PowerBonus = 11,
				RequiresSpecificTechnique = "Ratio Technique"
			},
			{
				Text = "[Straw Doll] Attack the curse through a link",
				Description = "You used a scrap of cursed residue as a link and struck the curse without putting the host down permanently.",
				Effects = { Reputation = 12, CursedEnergy = -8 },
				PowerBonus = 9,
				RequiresSpecificTechnique = "Straw Doll"
			}
		}
	},

	{
		Id = "cursed_object_found",
		Title = "Something Old in the Rubble",
		Body = "You uncover a cursed object during the mission. It hums in your hand. The assignment did not mention it.",
		Options = {
			{
				Text = "Report it to the higher-ups",
				Description = "You logged the object and turned it in. The higher-ups noted your discipline.",
				Effects = { Reputation = 8 },
				PowerBonus = 0
			},
			{
				Text = "Pocket it quietly",
				Description = "You slipped the object into your bag. No one saw. You felt its weight all the way home.",
				Effects = { Money = 400, Happiness = -2 },
				PowerBonus = 0
			},
			{
				Text = "Channel it against the curse",
				Description = "You poured cursed energy through the object. It worked, then it backfired.",
				Effects = { CursedEnergy = 15, Health = -10 },
				PowerBonus = 18
			},

			-- Technique-specific choices
			{
				Text = "[Ten Shadows] Feed it to a shikigami",
				Description = "You let one of your shikigami consume the cursed object's residue. It became stronger for the rest of the assignment.",
				Effects = { CursedEnergy = -8, Reputation = 4 },
				PowerBonus = 18,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Blood Manipulation] Test it with your blood",
				Description = "You exposed the object to your blood and watched how the curse reacted. Risky, but you learned how to use it safely.",
				Effects = { Health = -8, Smarts = 4, CursedEnergy = 8 },
				PowerBonus = 14,
				RequiresSpecificTechnique = "Blood Manipulation"
			},
			{
				Text = "[Limitless] Contain it with Infinity",
				Description = "You isolated the cursed object before it could contaminate anything nearby. The containment was clean enough to impress the higher-ups.",
				Effects = { Reputation = 12, CursedEnergy = -10 },
				PowerBonus = 8,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Disaster Flames] Burn away the residue",
				Description = "You burned the cursed residue until the object cracked open. The curse inside screamed before vanishing.",
				Effects = { Reputation = 7, CursedEnergy = -10 },
				PowerBonus = 17,
				RequiresSpecificTechnique = "Disaster Flames"
			}
		}
	},

	{
		Id = "trapped_student",
		Title = "Pinned and Bleeding",
		Body = "A younger sorcerer is pinned under debris. The curse is still moving. You can only handle one priority.",
		MinGrade = "Semi-Grade 3",
		Options = {
			{
				Text = "Free the student, then fight",
				Description = "You hauled the debris off them and pulled them clear. The curse had time to regroup, but the student lived.",
				Effects = { Reputation = 10, Happiness = 4 },
				PowerBonus = -12
			},
			{
				Text = "Kill the curse first, save them after",
				Description = "You ended the curse fast and turned back. The student lost more blood than they should have, but they pulled through.",
				Effects = { Reputation = 3, Happiness = -2 },
				PowerBonus = 5
			},
			{
				Text = "Do both at once with your technique",
				Description = "You used your cursed technique to pull the debris off mid-strike. It worked, barely.",
				Effects = { Reputation = 14, CursedEnergy = -10 },
				PowerBonus = -3,
				RequiresTechnique = true
			},

			-- Technique-specific choices
			{
				Text = "[Ten Shadows] Have a shikigami pull them free",
				Description = "A shikigami dragged the student out while you kept the curse occupied. It was the cleanest rescue possible under pressure.",
				Effects = { Reputation = 16, CursedEnergy = -10, Happiness = 5 },
				PowerBonus = 6,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Limitless] Hold the curse back with Infinity",
				Description = "You stepped between the student and the curse. Infinity bought enough time to free them without taking another hit.",
				Effects = { Reputation = 17, CursedEnergy = -12, Happiness = 4 },
				PowerBonus = 8,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Boogie Woogie] Swap the student with debris",
				Description = "You clapped and swapped the student out from under the debris. The curse hesitated just long enough for you to regain control.",
				Effects = { Reputation = 15, CursedEnergy = -9, Happiness = 4 },
				PowerBonus = 7,
				RequiresSpecificTechnique = "Boogie Woogie"
			},
			{
				Text = "[Thread Manipulation] Lift the debris cleanly",
				Description = "Threads wrapped around the broken concrete and lifted it just enough for the student to crawl free.",
				Effects = { Reputation = 14, CursedEnergy = -8, Happiness = 3 },
				PowerBonus = 5,
				RequiresSpecificTechnique = "Thread Manipulation"
			}
		}
	},

	{
		Id = "stronger_than_reported",
		Title = "The Briefing Was Wrong",
		Body = "Your assignment said Grade 3. The thing in front of you is not Grade 3. You have time for one decision.",
		MinGrade = "Grade 3",
		Options = {
			{
				Text = "Retreat and call for backup",
				Description = "You pulled back and reported the upgrade. No reward, but you were alive to file the paperwork.",
				Effects = { Smarts = 4, Happiness = -3 },
				PowerBonus = 0,
				ForceFail = true
			},
			{
				Text = "Push forward anyway",
				Description = "You committed. Whatever happened next happened because you decided it would.",
				Effects = { Happiness = -5 },
				PowerBonus = -25
			},
			{
				Text = "Set up a Black Flash attempt",
				Description = "You aligned your breathing and timed the cursed energy. Either this worked, or it ended you.",
				Effects = { CursedEnergy = -15 },
				PowerBonus = 30,
				RequiresTechnique = true
			},

			-- Technique-specific choices
			{
				Text = "[Limitless] Let it prove it can reach you",
				Description = "You stood still and let the curse try to touch you. It failed. The moment broke its pressure completely.",
				Effects = { Reputation = 18, CursedEnergy = -16, Happiness = 2 },
				PowerBonus = 28,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Ten Shadows] Sacrifice a shikigami opening",
				Description = "You used a shikigami as bait, forcing the curse to reveal how dangerous it really was. The opening was enough.",
				Effects = { Reputation = 14, CursedEnergy = -14, Happiness = -3 },
				PowerBonus = 24,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Ratio Technique] Find the impossible weak point",
				Description = "You forced yourself to calculate under pressure. The curse was stronger than reported, but still had a point that could break.",
				Effects = { Smarts = 3, CursedEnergy = -10 },
				PowerBonus = 25,
				RequiresSpecificTechnique = "Ratio Technique"
			},
			{
				Text = "[Idle Transfiguration] Touch it before it adapts",
				Description = "You gambled everything on contact. The curse's shape warped violently before it could finish adapting.",
				Effects = { Reputation = 10, Happiness = -8, CursedEnergy = -18 },
				PowerBonus = 32,
				RequiresSpecificTechnique = "Idle Transfiguration"
			},
			{
				Text = "[Disaster Flames] Overwhelm it before it moves",
				Description = "You flooded the area with cursed flame before the curse could reveal its full strength.",
				Effects = { Reputation = 12, CursedEnergy = -18 },
				PowerBonus = 30,
				RequiresSpecificTechnique = "Disaster Flames"
			}
		}
	},

	{
		Id = "phones_recording",
		Title = "Witnesses Gather",
		Body = "Civilians are watching too closely. They are catching every detail: the curse, your technique, your face. The veil should have hidden this.",
		Options = {
			{
				Text = "Scatter the witnesses fast",
				Description = "You moved fast and forced the crowd away. The cleanup worked, but frightened civilians spread complaints afterward.",
				Effects = { Reputation = -6, Money = -100 },
				PowerBonus = 0
			},
			{
				Text = "Pull up a barrier to block the view",
				Description = "You spent extra cursed energy raising a barrier. Witnesses only remembered warped shadows and useless fragments.",
				Effects = { CursedEnergy = -12, Reputation = 5 },
				PowerBonus = -5,
				RequiresTechnique = true
			},
			{
				Text = "Ignore them and finish the mission",
				Description = "You ignored the witnesses. The story spread fast, and cleanup took weeks.",
				Effects = { Reputation = -3 },
				PowerBonus = 6
			},

			-- Technique-specific choices
			{
				Text = "[Limitless] Warp the sightline around you",
				Description = "Witnesses saw distortion, light bending wrong, and nothing they could describe clearly. The higher-ups were annoyed but impressed.",
				Effects = { Reputation = 8, CursedEnergy = -8 },
				PowerBonus = 2,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Cursed Speech] Tell everyone to look away",
				Description = "Your command hit the crowd hard. Every witness turned away at once. Cleanup was easy, but some civilians looked shaken afterward.",
				Effects = { Reputation = 6, Happiness = -3, CursedEnergy = -10 },
				PowerBonus = 3,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Boogie Woogie] Swap evidence with rubble",
				Description = "You clapped. Every useful trace switched places with broken debris. The civilians panicked, but the evidence was gone.",
				Effects = { Reputation = 5, CursedEnergy = -8 },
				PowerBonus = 5,
				RequiresSpecificTechnique = "Boogie Woogie"
			},
			{
				Text = "[Static Binding] Muddle every account",
				Description = "You disrupted the area with cursed static. Every witness account came out confused before it could spread.",
				Effects = { Reputation = 7, CursedEnergy = -7 },
				PowerBonus = 4,
				RequiresSpecificTechnique = "Static Binding"
			}
		}
	},

	{
		Id = "rogue_offers_help",
		Title = "An Unfamiliar Sorcerer",
		Body = "A sorcerer you don't recognize steps out of the shadows during your mission. They offer help in exchange for a cut of the contract.",
		MinGrade = "Grade 3",
		Options = {
			{
				Text = "Accept the deal",
				Description = "You worked together and finished the curse fast. They took their cut and disappeared before introductions.",
				Effects = { Money = -200, Happiness = 2 },
				PowerBonus = 15
			},
			{
				Text = "Refuse and fight alone",
				Description = "You waved them off. The rogue watched from a distance until you were done.",
				Effects = { Reputation = 2 },
				PowerBonus = 0
			},
			{
				Text = "Accept, then report them after",
				Description = "You took the help, then reported the rogue's existence. Your superiors were interested. The rogue was not pleased.",
				Effects = { Reputation = 8, Money = -200, Happiness = -5 },
				PowerBonus = 12
			},

			-- Technique-specific choices
			{
				Text = "[Cursed Speech] Command them to reveal their name",
				Description = "Your command forced the rogue's name out before they could stop themselves. They helped, but they left furious.",
				Effects = { Reputation = 10, CursedEnergy = -8, Happiness = -4 },
				PowerBonus = 10,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Ten Shadows] Keep a shikigami tracking them",
				Description = "You accepted the help while a shikigami quietly followed their shadow afterward. The higher-ups liked the information.",
				Effects = { Reputation = 12, CursedEnergy = -9, Smarts = 2 },
				PowerBonus = 12,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Mirror Step] Leave a reflection watching them",
				Description = "You let a reflection track the rogue's movements after the mission. You learned more than they meant to reveal.",
				Effects = { Reputation = 10, Smarts = 3, CursedEnergy = -8 },
				PowerBonus = 11,
				RequiresSpecificTechnique = "Mirror Step"
			}
		}
	},

	{
		Id = "begging_curse",
		Title = "It Spoke",
		Body = "The curse stops attacking and speaks. It begs you not to exorcise it. Its voice sounds almost human.",
		MinGrade = "Semi-Grade 2",
		Options = {
			{
				Text = "Exorcise it immediately",
				Description = "You did not hesitate. A curse begging was still a curse. The mission ended quickly.",
				Effects = { Reputation = 5, Happiness = -3 },
				PowerBonus = 8
			},
			{
				Text = "Listen to what it says",
				Description = "You let it speak. Most of it was nonsense, but some details matched old missing persons reports.",
				Effects = { Smarts = 5, Happiness = -5 },
				PowerBonus = -5
			},
			{
				Text = "Let it go",
				Description = "You let the curse disappear into the city. You told yourself it was different. You were not sure you believed that.",
				Effects = { Reputation = -18, Happiness = 4 },
				PowerBonus = 0,
				ForceFail = true
			},

			-- Technique-specific choices
			{
				Text = "[Cursed Speech] Force it to tell the truth",
				Description = "You ordered the curse to speak honestly. Its answer was ugly, useful, and hard to forget.",
				Effects = { Smarts = 6, Happiness = -8, CursedEnergy = -9 },
				PowerBonus = 5,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Idle Transfiguration] Touch its soul shape",
				Description = "You reached into the curse's form and felt the hatred that made it. You understood it better than you wanted to.",
				Effects = { Smarts = 5, Happiness = -12, CursedEnergy = -12 },
				PowerBonus = 14,
				RequiresSpecificTechnique = "Idle Transfiguration"
			},
			{
				Text = "[Grave Bloom] Bury its hatred cleanly",
				Description = "Cursed flowers bloomed around the curse and swallowed its shape. The area felt lighter afterward.",
				Effects = { Reputation = 9, Happiness = 3, CursedEnergy = -9 },
				PowerBonus = 10,
				RequiresSpecificTechnique = "Grave Bloom"
			}
		}
	},

	{
		Id = "child_with_cursed_energy",
		Title = "A Child in the Rubble",
		Body = "You find a child in the wreckage. They are alive, untouched by the curse — but their cursed energy is intense. Possibly a Cursed Womb.",
		MinGrade = "Grade 2",
		Options = {
			{
				Text = "Take them to the higher-ups",
				Description = "You handed the child over for evaluation. Whatever they decided was on them, not you.",
				Effects = { Reputation = 6 },
				PowerBonus = 0
			},
			{
				Text = "Hide them and let them live",
				Description = "You quietly let the child slip away into the city. You did not file a report on them.",
				Effects = { Happiness = 6, Reputation = -10 },
				PowerBonus = 0
			},
			{
				Text = "End them on the spot",
				Description = "You decided the risk was too high. You finished it before they could grow into a problem.",
				Effects = { Happiness = -25, Reputation = -5 },
				PowerBonus = 4
			},

			-- Technique-specific choices
			{
				Text = "[Limitless] Keep them contained until help arrives",
				Description = "You kept the child isolated behind Infinity until proper containment arrived. No one got hurt, but the child never stopped staring at you.",
				Effects = { Reputation = 14, Happiness = -4, CursedEnergy = -12 },
				PowerBonus = 4,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Ten Shadows] Hide them inside a shadow",
				Description = "You hid the child long enough to decide their fate yourself. The report you filed was incomplete.",
				Effects = { Happiness = 8, Reputation = -6, CursedEnergy = -12 },
				PowerBonus = 2,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Idle Transfiguration] Study what they are",
				Description = "You touched their soul structure and realized they were not fully human, but not fully curse either.",
				Effects = { Smarts = 8, Happiness = -10, Reputation = -4, CursedEnergy = -12 },
				PowerBonus = 5,
				RequiresSpecificTechnique = "Idle Transfiguration"
			},
			{
				Text = "[Paper Shikigami] Leave a watcher on them",
				Description = "You let the child go, but sent a paper shikigami to watch from a distance. It was not mercy. It was surveillance.",
				Effects = { Smarts = 4, Happiness = 5, Reputation = -5, CursedEnergy = -8 },
				PowerBonus = 2,
				RequiresSpecificTechnique = "Paper Shikigami"
			}
		}
	},

	{
		Id = "familiar_face",
		Title = "You Know That Face",
		Body = "The curse takes a form that looks like someone you knew. It moves like them, speaks like them. You know it is a trick. It still gets to you.",
		MinGrade = "Grade 1",
		Options = {
			{
				Text = "Cut through the illusion immediately",
				Description = "You did not hesitate. The form shattered on contact. The curse beneath was furious.",
				Effects = { Reputation = 8, Happiness = -4 },
				PowerBonus = 5
			},
			{
				Text = "Hesitate, then commit",
				Description = "You froze for half a second. The curse used it. You finished the job, but it cost you.",
				Effects = { Health = -15, Happiness = -10 },
				PowerBonus = -8
			},
			{
				Text = "Speak to it first",
				Description = "You spoke to the form, knowing it was a curse. You learned a few things the briefing did not include.",
				Effects = { Smarts = 6, Happiness = -8 },
				PowerBonus = -3,
				RequiresSmarts = 60
			},

			-- Technique-specific choices
			{
				Text = "[Mirror Step] Step through the false reflection",
				Description = "You recognized the illusion as a reflection and moved through it. The curse lost its psychological advantage instantly.",
				Effects = { Smarts = 5, Happiness = -3, CursedEnergy = -10 },
				PowerBonus = 16,
				RequiresSpecificTechnique = "Mirror Step"
			},
			{
				Text = "[Cursed Speech] Command it to show its real face",
				Description = "Your command ripped the familiar face away. The thing underneath was worse, but at least it was honest.",
				Effects = { Reputation = 10, Happiness = -7, CursedEnergy = -12 },
				PowerBonus = 15,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Shadow Stitch] Pin the fake form in place",
				Description = "You stitched the curse's shadow to the floor. The familiar face kept talking, but it could not move anymore.",
				Effects = { Reputation = 9, CursedEnergy = -10, Happiness = -4 },
				PowerBonus = 17,
				RequiresSpecificTechnique = "Shadow Stitch"
			},
			{
				Text = "[Grave Bloom] Let the memory die properly",
				Description = "Cursed flowers grew around the illusion and crushed it gently. It still hurt, but you did not let it control you.",
				Effects = { Happiness = 3, Reputation = 7, CursedEnergy = -10 },
				PowerBonus = 14,
				RequiresSpecificTechnique = "Grave Bloom"
			}
		}
	}
}

function BitKaisenSituations.GetSituationById(id)
	for _, situation in ipairs(BitKaisenSituations.Database) do
		if situation.Id == id then
			return situation
		end
	end

	return nil
end

local function cleanTechniqueValue(value)
	local text = tostring(value or "None")

	if text == "" or text == "None" or text == "nil" or text == "Unknown" then
		return nil
	end

	return text
end

local function normalizeTechniqueName(value)
	local text = cleanTechniqueValue(value)
	if not text then
		return nil
	end

	text = string.lower(text)
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	return text
end

local function getTechniqueCandidates(stats)
	stats = stats or {}

	local candidates = {}
	local seen = {}

	local function add(value)
		local clean = cleanTechniqueValue(value)
		if not clean then
			return
		end

		local key = normalizeTechniqueName(clean)
		if key and not seen[key] then
			seen[key] = true
			table.insert(candidates, clean)
		end
	end

	-- Current-life technique.
	add(stats.CursedTechnique)

	-- Inherited / clan-born techniques often live here for 2nd gen+ lives.
	add(stats.InnateTechnique)
	add(stats.PlayerClanInnateTechnique)
	add(stats.ClanInnateTechnique)
	add(stats.InheritedTechnique)
	add(stats.BloodlineTechnique)

	return candidates
end

local function hasAnyUsableTechnique(stats)
	stats = stats or {}

	if stats.TechniqueUsable == false then
		return false
	end

	local candidates = getTechniqueCandidates(stats)
	if #candidates > 0 then
		return true
	end

	return stats.TechniqueKnown == true or stats.TechniqueAwakened == true
end

local function getPrimaryTechnique(stats)
	local candidates = getTechniqueCandidates(stats)
	return candidates[1] or "None"
end

local function hasSpecificTechnique(stats, requiredTechnique)
	stats = stats or {}

	if stats.TechniqueUsable == false then
		return false
	end

	local required = normalizeTechniqueName(requiredTechnique)
	if not required then
		return false
	end

	for _, techniqueName in ipairs(getTechniqueCandidates(stats)) do
		if normalizeTechniqueName(techniqueName) == required then
			return true
		end
	end

	return false
end

local function buildTechniqueStatsForMissionOption(stats, effectiveTechnique)
	local copy = {}

	for key, value in pairs(stats or {}) do
		copy[key] = value
	end

	copy.CursedTechnique = effectiveTechnique or getPrimaryTechnique(stats)
	copy.TechniqueKnown = true
	copy.TechniqueUsable = copy.TechniqueUsable ~= false
	copy.TechniqueAwakened = copy.TechniqueAwakened == true or copy.TechniqueUsable == true

	return copy
end

function BitKaisenSituations.GetOptionsForPlayer(situation, stats)
	local available = {}

	if not situation or not situation.Options then
		return available
	end

	stats = stats or {}

	local playerTechnique = getPrimaryTechnique(stats)
	local playerHasTechnique = hasAnyUsableTechnique(stats)

	for _, option in ipairs(situation.Options) do
		local ok = true
		local optionToInsert = option

		if option.RequiresTechnique then
			if not playerHasTechnique then
				ok = false
			else
				local generated = nil

				if BitKaisenStats.GetTechniqueMissionOption then
					generated = BitKaisenStats.GetTechniqueMissionOption(
						buildTechniqueStatsForMissionOption(stats, playerTechnique),
						option
					)
				end

				if generated then
					optionToInsert = generated
				end
			end
		end

		if ok and option.RequiresSpecificTechnique then
			if not hasSpecificTechnique(stats, option.RequiresSpecificTechnique) then
				ok = false
			end
		end

		if ok and option.RequiresSmarts then
			if (stats.Smarts or 0) < option.RequiresSmarts then
				ok = false
			end
		end

		if ok then
			table.insert(available, optionToInsert)
		end
	end

	return available
end

function BitKaisenSituations.RollSituation(stats, missionData)
	if not missionData then
		return nil
	end

	local missionRank = GRADE_ORDER[missionData.Grade] or 1
	local possible = {}

	for _, situation in ipairs(BitKaisenSituations.Database) do
		local minRank = GRADE_ORDER[situation.MinGrade or ""] or 1
		local maxRank = GRADE_ORDER[situation.MaxGrade or ""] or 999

		if missionRank >= minRank and missionRank <= maxRank then
			local available = BitKaisenSituations.GetOptionsForPlayer(situation, stats)

			if #available >= 2 then
				table.insert(possible, situation)
			end
		end
	end

	if #possible <= 0 then
		return nil
	end

	return possible[math.random(1, #possible)]
end

return BitKaisenSituations
