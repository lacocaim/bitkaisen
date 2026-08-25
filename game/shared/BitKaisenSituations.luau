-- ModuleScript: BitKaisenSituations
-- Location: ReplicatedStorage
--
-- Purpose:
-- Handles mission situation events and filters which choices the player can take.
--
-- Supports (per option):
-- RequiresTechnique = true
-- RequiresSpecificTechnique = "Limitless"
-- RequiresSmarts = 50
-- RequiresOrigin = "Zenin Clan"          -- exact origin DisplayName
-- RequiresOriginCategory = "Clan"        -- "Family" | "Clan" | "Lineage" | "Race"
-- ForceSuccess = true
-- ForceFail = true
--
-- Per situation: MinGrade / MaxGrade.
-- NOTE: RollSituation only offers a situation when at least 2 of its options
-- pass the filters, so every entry needs 3+ ungated options or it will simply
-- never appear for most players.

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
		Body = "You find a child in the wreckage. They are alive, untouched by the curse - but their cursed energy is intense. Possibly a Cursed Womb.",
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
	},

	-- =====================================================================
	-- Update 28: more situations, and bloodline choices inside them. Every
	-- entry below keeps at least three ungated options so it stays reachable
	-- for a civilian with no technique, then layers technique and clan
	-- branches on top for players who have them.
	-- =====================================================================

	{
		Id = "school_trapped_under",
		Title = "Under the Gymnasium",
		Body = "The floor of a school gym collapsed into an old cursed pit. Nine students are alive down there and the walls are still moving. You can hear them.",
		MinGrade = "Grade 4",
		MaxGrade = "Grade 1",
		Options = {
			{
				Text = "Go down alone and start pulling them out",
				Description = "You went down without waiting for backup and carried them up two at a time. All nine lived. Your shoulder did not.",
				Effects = { Reputation = 14, Health = -20, Happiness = 6 },
				PowerBonus = -8
			},
			{
				Text = "Hold the entrance and let the rescue team work",
				Description = "You held the mouth of the pit while the team extracted the students behind you. Slower, safer, and nobody died.",
				Effects = { Reputation = 8, Health = -6 },
				PowerBonus = 4
			},
			{
				Text = "Collapse the pit and cut the curse off from them",
				Description = "You brought the far wall down to seal the curse away. Two students were hurt in the fall. Seven walked out clean.",
				Effects = { Reputation = 2, Happiness = -8 },
				PowerBonus = 14
			},
			{
				Text = "Study the pit before doing anything",
				Description = "You read the structure before moving and found the one route that held. Everyone came out, and you learned what made the pit.",
				Effects = { Reputation = 10, Smarts = 5 },
				PowerBonus = 6,
				RequiresSmarts = 55
			},
			{
				Text = "[Limitless] Hold the ceiling apart from below",
				Description = "You stood under the worst of it and simply did not let the distance close. The students walked out beneath you.",
				Effects = { Reputation = 18, CursedEnergy = -16, Happiness = 5 },
				PowerBonus = 12,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Ten Shadows] Send the dogs down for the ones you cannot see",
				Description = "The divine dogs found the two students nobody had counted. You would not have known they were there.",
				Effects = { Reputation = 16, CursedEnergy = -11, Happiness = 4 },
				PowerBonus = 9,
				RequiresSpecificTechnique = "Ten Shadows"
			},
			{
				Text = "[Barrier Technique] Curtain the pit before the parents arrive",
				Description = "You raised a curtain over the whole yard first. The rescue was slower and no civilian ever learned what was underneath.",
				Effects = { Reputation = 12, CursedEnergy = -10, SocietyAttention = -6 },
				PowerBonus = 6,
				RequiresSpecificTechnique = "Barrier Technique"
			},
			{
				Text = "[Zenin] Handle it the way the clan taught you",
				Description = "You triaged by survivability, exactly as you were raised to, and saved the most that could be saved. It worked. You did not enjoy how easy the arithmetic was.",
				Effects = { Reputation = 11, ClanReputation = 6, Happiness = -6 },
				PowerBonus = 10,
				RequiresOrigin = "Zenin Clan"
			},
			{
				Text = "[Kusakabe] Do the boring thing that keeps everyone alive",
				Description = "You refused to go down until the anchors were set. Nobody praised it. Nobody died either.",
				Effects = { Reputation = 7, Health = 4, Happiness = 4 },
				PowerBonus = 5,
				RequiresOrigin = "Kusakabe Lineage"
			}
		}
	},

	{
		Id = "curse_wearing_child",
		Title = "It Is Using a Child",
		Body = "The curse has taken a child's body and is walking it toward you. The child is still inside. You can feel both of them.",
		MinGrade = "Semi-Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Restrain the body without striking",
				Description = "You pinned the body and held on while it screamed in two voices. It took nineteen minutes. The child survived.",
				Effects = { Reputation = 12, Health = -16, Happiness = 4 },
				PowerBonus = -10
			},
			{
				Text = "Strike fast and end it",
				Description = "You ended the curse in one motion. The child stopped moving at the same time. Nobody blamed you out loud.",
				Effects = { Reputation = -6, Happiness = -20, Fear = 8 },
				PowerBonus = 16
			},
			{
				Text = "Talk to the child, not the curse",
				Description = "You spoke past the curse to whoever was still in there. Something answered. The grip loosened enough for you to work.",
				Effects = { Reputation = 9, Happiness = 2, CursedEnergy = -5 },
				PowerBonus = 2
			},
			{
				Text = "[Idle Transfiguration] Separate them at the soul",
				Description = "You reached past the body and pulled the two apart where they actually met. The child woke up whole. You did not explain the method to anyone.",
				Effects = { Reputation = 15, CursedEnergy = -18, Happiness = 3, Fear = 6 },
				PowerBonus = 14,
				RequiresSpecificTechnique = "Idle Transfiguration"
			},
			{
				Text = "[Cursed Speech] Order it out",
				Description = "One word. The curse left the body because it had no choice. Your throat paid for it and the child lived.",
				Effects = { Reputation = 16, Health = -9, CursedEnergy = -14 },
				PowerBonus = 15,
				RequiresSpecificTechnique = "Cursed Speech"
			},
			{
				Text = "[Cursed Spirit Manipulation] Take it into your collection",
				Description = "You pulled the curse out and swallowed it whole. The child dropped, breathing. You now carry whatever it was.",
				Effects = { Reputation = 11, CursedEnergy = -12, CursedResentment = 5 },
				PowerBonus = 13,
				RequiresSpecificTechnique = "Cursed Spirit Manipulation"
			},
			{
				Text = "[Kamo] Read the blood to find where the child ends",
				Description = "You found the boundary by pulse alone and worked inside it. Clean, precise, and exactly the kind of thing people are afraid your family can do.",
				Effects = { Reputation = 10, Fear = 6, CursedEnergy = -9 },
				PowerBonus = 12,
				RequiresOrigin = "Kamo Clan"
			},
			{
				Text = "[Clan] Call for clan support and hold until it arrives",
				Description = "You sent word up the family line and held the child still until people with more authority than you took over. The outcome was good. The credit was not yours.",
				Effects = { ClanReputation = 8, Reputation = 3, Happiness = -3 },
				PowerBonus = 3,
				RequiresOriginCategory = "Clan"
			}
		}
	},

	{
		Id = "civilian_witness",
		Title = "Someone Saw Everything",
		Body = "A civilian watched the whole exorcism from a stairwell. They are not screaming. They are looking at you, and they are not going to forget.",
		MinGrade = "Grade 4",
		MaxGrade = "Grade 1",
		Options = {
			{
				Text = "Tell them the truth",
				Description = "You explained what curses are and what you do about them. They took it better than expected. Somewhere, a form got filed about you.",
				Effects = { Reputation = 4, SocietyAttention = 7, Happiness = 3 },
				PowerBonus = 0
			},
			{
				Text = "Say nothing and walk away",
				Description = "You left without a word. They will decide for themselves what they saw, and you will never know what they decided.",
				Effects = { SocietyAttention = 3, Happiness = -3 },
				PowerBonus = 0
			},
			{
				Text = "Report them and let the system handle it",
				Description = "You filed it correctly. Someone else arrived to manage the witness. You did not ask what managing meant.",
				Effects = { Reputation = 6, SocietyAttention = -5, Happiness = -6 },
				PowerBonus = 0
			},
			{
				Text = "Convince them they saw nothing",
				Description = "You talked circles around them until they doubted themselves. It worked. You did not like how easily it worked.",
				Effects = { SocietyAttention = -6, Happiness = -4, Smarts = 3 },
				PowerBonus = 0,
				RequiresSmarts = 60
			},
			{
				Text = "[Barrier Technique] Curtain the stairwell and finish quietly",
				Description = "The curtain went up around them mid-thought. When it dropped, the stairwell was empty of anything worth remembering.",
				Effects = { SocietyAttention = -9, CursedEnergy = -8, Reputation = 3 },
				PowerBonus = 0,
				RequiresSpecificTechnique = "Barrier Technique"
			},
			{
				Text = "[Civilian] Tell them the way you wish someone had told you",
				Description = "You remembered being the one on the stairs, and being told you imagined it. So you sat down and explained it properly instead.",
				Effects = { Happiness = 10, Reputation = 5, SocietyAttention = 5 },
				PowerBonus = 0,
				RequiresOrigin = "Civilian Family"
			},
			{
				Text = "[Kenjaku] Note their face and move on",
				Description = "You recorded them, the way your family records everything, and filed it against a use you have not thought of yet.",
				Effects = { Smarts = 6, CursedResentment = 4, Happiness = -5 },
				PowerBonus = 0,
				RequiresOrigin = "Kenjaku Clan"
			}
		}
	},

	{
		Id = "rival_sorcerer_claim",
		Title = "Someone Else Wants The Kill",
		Body = "Another sorcerer arrives mid-fight and makes it clear the curse is theirs. The curse is still standing. So are both of you.",
		MinGrade = "Semi-Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Let them have it",
				Description = "You stepped back and watched them finish it. They took the credit and remembered that you let them.",
				Effects = { Reputation = -3, Happiness = -2 },
				PowerBonus = 0
			},
			{
				Text = "Fight it together",
				Description = "You worked around each other badly for the first minute and well after that. The curse fell fast, and you both signed the report.",
				Effects = { Reputation = 8, Health = -7 },
				PowerBonus = 10
			},
			{
				Text = "Finish it before they can",
				Description = "You ended it while they were still talking. They will not forget that either.",
				Effects = { Reputation = 9, Fear = 6, Happiness = 2 },
				PowerBonus = 8
			},
			{
				Text = "[Todo] Ask what kind of person they like first",
				Description = "You asked the only question that matters, mid-fight, and got an answer you respected. You have a friend now, whether they wanted one or not.",
				Effects = { Reputation = 10, Happiness = 12, CursedEnergy = 4 },
				PowerBonus = 12,
				RequiresOrigin = "Todo Lineage"
			},
			{
				Text = "[Mei Mei] Negotiate a split before either of you moves",
				Description = "You settled the fee before the fight resumed. They agreed because you were right about the numbers.",
				Effects = { Money = 3200, Reputation = -2, Smarts = 4 },
				PowerBonus = 6,
				RequiresOrigin = "Mei Mei Lineage"
			},
			{
				Text = "[Gojo] Remind them who is standing here",
				Description = "You did not have to say much. The name did the work, and you noticed how much you disliked that it did.",
				Effects = { Reputation = 12, Fear = 8, Happiness = -4 },
				PowerBonus = 14,
				RequiresOrigin = "Gojo Clan"
			}
		}
	},

	{
		Id = "colleague_will_not_make_it",
		Title = "They Are Not Going To Make It",
		Body = "A sorcerer from your team is bleeding out behind cover. The curse is still active. You have time for one of these things, not both.",
		MinGrade = "Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Stay with them",
				Description = "You stayed. The curse got away and someone else dealt with it later. They were not alone at the end.",
				Effects = { Reputation = -8, Happiness = -10, CursedResentment = 4 },
				PowerBonus = -12
			},
			{
				Text = "Finish the curse first",
				Description = "You ended the curse and came back as fast as you could. It was not fast enough, and you did the correct thing.",
				Effects = { Reputation = 10, Happiness = -16, Fear = 5 },
				PowerBonus = 15
			},
			{
				Text = "Drag them out under fire",
				Description = "You carried them through the open with the curse at your back. You both made it to the door. Only one of you was still conscious.",
				Effects = { Reputation = 12, Health = -24, Happiness = 6 },
				PowerBonus = -6
			},
			{
				Text = "[Nanami] Do the job, then grieve on your own time",
				Description = "You separated the two tasks the way you have always separated them. It is the only reason you are still able to do this work.",
				Effects = { Reputation = 11, Happiness = -12, Smarts = 4 },
				PowerBonus = 12,
				RequiresOrigin = "Nanami Lineage"
			},
			{
				Text = "[Geto] Notice what you are being asked to trade",
				Description = "You saved them, and afterwards you could not stop turning over how routinely people like you are spent on people who will never know your name.",
				Effects = { Reputation = 9, CursedResentment = 9, Happiness = -8 },
				PowerBonus = 8,
				RequiresOrigin = "Geto Lineage"
			}
		}
	},

	{
		Id = "cursed_tool_in_the_rubble",
		Title = "Something Is Buried Here",
		Body = "Under the collapsed shrine there is a blade nobody has touched in three hundred years. The curse you came for is dead. The blade is not.",
		MinGrade = "Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Take it",
				Description = "You took it. Nobody logged it, and it has been warm ever since.",
				Effects = { Reputation = 3, CursedEnergy = 6, CursedResentment = 5 },
				PowerBonus = 10
			},
			{
				Text = "Report it and leave it where it is",
				Description = "You filed it correctly and a retrieval team came for it. You did not see where it went.",
				Effects = { Reputation = 9, SocietyAttention = 4, Happiness = -2 },
				PowerBonus = 0
			},
			{
				Text = "Destroy it",
				Description = "You broke it where it lay. Something screamed that was not the blade. You do not regret it.",
				Effects = { Reputation = 4, Health = -10, Fear = 5 },
				PowerBonus = 4
			},
			{
				Text = "Study the seals before touching anything",
				Description = "You read the seals first and found the one still holding. Whoever buried this wanted it to stay buried, and they had reasons.",
				Effects = { Smarts = 6, Reputation = 7 },
				PowerBonus = 6,
				RequiresSmarts = 60
			},
			{
				Text = "[Tool Manipulation] Test what it answers to",
				Description = "You reached for it without moving and it came. That told you more about it than any inspection would have.",
				Effects = { CursedEnergy = -8, Reputation = 6, Smarts = 4 },
				PowerBonus = 12,
				RequiresSpecificTechnique = "Tool Manipulation"
			},
			{
				Text = "[Tsukigane] Read the forge marks",
				Description = "You knew the smith's hand on sight. It was made by your family, and it was buried on purpose.",
				Effects = { ClanReputation = 8, Smarts = 5, Happiness = -3 },
				PowerBonus = 9,
				RequiresOrigin = "Tsukigane Clan"
			},
			{
				Text = "[Mei Mei] Price it before anyone else arrives",
				Description = "You knew what it was worth before you knew what it did, and you moved accordingly.",
				Effects = { Money = 4500, Reputation = -3 },
				PowerBonus = 5,
				RequiresOrigin = "Mei Mei Lineage"
			}
		}
	},

	{
		Id = "student_froze",
		Title = "The Student Froze",
		Body = "The first year you were assigned to has stopped moving. The curse is eight metres away and closing, and they are looking at you instead of it.",
		MinGrade = "Grade 2",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Put yourself between them and it",
				Description = "You stepped in front. They watched you take it and something in them unlocked afterwards.",
				Effects = { Reputation = 10, Health = -18, Happiness = 6 },
				PowerBonus = -5
			},
			{
				Text = "Order them to move",
				Description = "You shouted. They moved. They also stopped trusting themselves for a long time afterwards.",
				Effects = { Reputation = 6, Happiness = -5 },
				PowerBonus = 6
			},
			{
				Text = "Talk them through it",
				Description = "You told them exactly what to do, one step at a time, while it closed. They did all of it. They will remember that they did.",
				Effects = { Reputation = 12, Happiness = 9, Health = -8 },
				PowerBonus = 2
			},
			{
				Text = "[Kusakabe] Teach them the thing that keeps them alive",
				Description = "You did not teach them to win. You taught them how to leave, and you made them practise it before the next assignment.",
				Effects = { Reputation = 8, Happiness = 7, Smarts = 4 },
				PowerBonus = 4,
				RequiresOrigin = "Kusakabe Lineage"
			},
			{
				Text = "[Zenin] Let them find out what they are",
				Description = "You intervened at the last possible moment, exactly as the clan does it. They survived and they learned. They also flinched when you approached afterwards.",
				Effects = { ClanReputation = 6, Reputation = 4, Happiness = -7 },
				PowerBonus = 11,
				RequiresOrigin = "Zenin Clan"
			},
			{
				Text = "[Simple Domain] Give them ground to stand on",
				Description = "You opened your circle around both of you. Inside it they stopped shaking, and that was enough.",
				Effects = { Reputation = 11, CursedEnergy = -9, Happiness = 5 },
				PowerBonus = 8,
				RequiresSpecificTechnique = "Simple Domain"
			}
		}
	},

	{
		Id = "special_grade_arrives",
		Title = "That Is Not Its Grade",
		Body = "The assessment said Grade 2. The thing unfolding out of the ceiling is not Grade 2, and the exit is behind it.",
		MinGrade = "Grade 2",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Buy time and call it in",
				Description = "You held it for six minutes until support arrived. Six minutes is a very long time.",
				Effects = { Reputation = 11, Health = -22 },
				PowerBonus = -6
			},
			{
				Text = "Fight it",
				Description = "You fought something well above your grade and lived, which is the only reason anyone praised the decision.",
				Effects = { Reputation = 14, Health = -28, Fear = 8 },
				PowerBonus = 12
			},
			{
				Text = "Get the civilians out and abandon the site",
				Description = "You emptied the building and let the site go. The paperwork called it a failure. Nobody died.",
				Effects = { Reputation = -4, Happiness = 8 },
				PowerBonus = 0
			},
			{
				Text = "[Limitless] Refuse to let it reach you",
				Description = "It came at you with everything and arrived at nothing. You walked out through where it had been standing.",
				Effects = { Reputation = 18, CursedEnergy = -20, Fear = 10 },
				PowerBonus = 18,
				RequiresSpecificTechnique = "Limitless"
			},
			{
				Text = "[Cursed Spirit Manipulation] Answer it with your own",
				Description = "You emptied your collection into the room. What was left standing at the end was yours.",
				Effects = { Reputation = 15, CursedEnergy = -18, CursedResentment = 4 },
				PowerBonus = 16,
				RequiresSpecificTechnique = "Cursed Spirit Manipulation"
			},
			{
				Text = "[Kashimo] Finally",
				Description = "You had been waiting your whole life for something that could actually hurt you. You did not stop smiling the entire fight.",
				Effects = { Reputation = 12, Health = -26, Happiness = 15 },
				PowerBonus = 17,
				RequiresOrigin = "Kashimo Lineage"
			}
		}
	},

	{
		Id = "clan_asks_a_favour",
		Title = "The Family Would Like A Word",
		Body = "Mid-assignment, a message reaches you from your own bloodline. They want something handled here, quietly, and they did not phrase it as a request.",
		MinGrade = "Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Do it",
				Description = "You handled it and said nothing in the report. The family noticed. So did someone else.",
				Effects = { ClanReputation = 10, Reputation = -4, SocietyAttention = 5 },
				PowerBonus = 4
			},
			{
				Text = "Refuse",
				Description = "You told them no, in writing, which made it permanent. Something closed behind you that will not reopen.",
				Effects = { ClanReputation = -12, Reputation = 6, Happiness = -5 },
				PowerBonus = 0
			},
			{
				Text = "Do the assignment and pretend the message never arrived",
				Description = "You finished the job you were sent to do. Nobody can prove you read it, and everybody knows you did.",
				Effects = { Reputation = 5, ClanReputation = -4, Smarts = 3 },
				PowerBonus = 2
			},
			{
				Text = "Find out who benefits first",
				Description = "You traced the request back before answering it, and found out which branch of the family sent it and why. That was worth more than either answer.",
				Effects = { Smarts = 7, ClanReputation = 4 },
				PowerBonus = 3,
				RequiresSmarts = 65
			},
			{
				Text = "[Kenjaku] Agree, and start your own file on them",
				Description = "You did what they asked and began recording what they wanted it for. Your family understands that arrangement perfectly.",
				Effects = { ClanReputation = 8, Smarts = 6, CursedResentment = 3 },
				PowerBonus = 4,
				RequiresOrigin = "Kenjaku Clan"
			},
			{
				Text = "[Branch] Do it, because branch families do not refuse",
				Description = "There was never really a choice. You handled it, and the main house will never know your name was on it.",
				Effects = { ClanReputation = 9, Happiness = -8 },
				PowerBonus = 3,
				RequiresOrigin = "Branch Sorcerer Family"
			}
		}
	},

	{
		Id = "curse_that_talks",
		Title = "It Wants To Talk",
		Body = "The curse has stopped attacking. It is sitting in the middle of the room, and it is speaking in complete sentences.",
		MinGrade = "Grade 2",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Listen",
				Description = "You let it talk. Most of it was nonsense. One part of it was not, and you have not been able to forget that part.",
				Effects = { Smarts = 6, Happiness = -8, CursedResentment = 4 },
				PowerBonus = -4
			},
			{
				Text = "Kill it mid-sentence",
				Description = "You did not let it finish. You told yourself that was the professional decision.",
				Effects = { Reputation = 7, Happiness = -4, Fear = 5 },
				PowerBonus = 12
			},
			{
				Text = "Ask it what it was made from",
				Description = "It answered honestly. Someone you have never met was afraid of something for long enough to make this.",
				Effects = { Smarts = 8, Happiness = -6 },
				PowerBonus = 0
			},
			{
				Text = "[Geto] Recognise what it is actually saying",
				Description = "It described the people who made it, and you found that you agreed with it about them. You killed it anyway, and that bothered you more.",
				Effects = { CursedResentment = 10, Smarts = 5, Happiness = -9 },
				PowerBonus = 8,
				RequiresOrigin = "Geto Lineage"
			},
			{
				Text = "[Deadly Sentencing] Try it properly",
				Description = "You held court on the floor of a ruined building. It made its case. You still returned a verdict.",
				Effects = { Reputation = 12, CursedEnergy = -14, Smarts = 6 },
				PowerBonus = 15,
				RequiresSpecificTechnique = "Deadly Sentencing"
			},
			{
				Text = "[Higuruma] Hear the whole case before deciding",
				Description = "You could not bring yourself to end it without listening first. What it said was not a defence, but it was true.",
				Effects = { Smarts = 8, Happiness = -7, Reputation = 5 },
				PowerBonus = 6,
				RequiresOrigin = "Higuruma Lineage"
			}
		}
	},

	{
		Id = "assignment_was_wrong",
		Title = "The Assignment Was Wrong",
		Body = "There is no curse here. There is a sorcerer, and the people they were sent to protect are the ones lying on the floor.",
		MinGrade = "Grade 2",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Detain them",
				Description = "You brought them in alive. The hearing took months and you were called to it four times.",
				Effects = { Reputation = 10, SocietyAttention = 8, Health = -12 },
				PowerBonus = 4
			},
			{
				Text = "Kill them",
				Description = "You decided on the spot and acted. It was ruled justified. You still think about the ruling.",
				Effects = { Reputation = 4, Happiness = -14, Fear = 9, WantedLevel = 3 },
				PowerBonus = 14
			},
			{
				Text = "Let them explain",
				Description = "You listened to the whole thing before doing anything. Some of it turned out to be true, which made it worse.",
				Effects = { Smarts = 6, Happiness = -8, Reputation = 3 },
				PowerBonus = -3
			},
			{
				Text = "Secure the scene and report it exactly as found",
				Description = "You touched nothing and wrote down everything. The report was used at the hearing, word for word.",
				Effects = { Reputation = 12, Smarts = 5, SocietyAttention = 5 },
				PowerBonus = 0
			},
			{
				Text = "[Nanami] Follow procedure to the letter",
				Description = "You did the correct thing in the correct order and let the system carry it from there. It is the only way this job stays survivable.",
				Effects = { Reputation = 11, Smarts = 4, Happiness = -6 },
				PowerBonus = 5,
				RequiresOrigin = "Nanami Lineage"
			},
			{
				Text = "[Lineage] Handle it before it becomes a hearing",
				Description = "Your name carries enough weight to close this quietly, and you used it. Nobody outside the family will ever read about this.",
				Effects = { ClanReputation = 7, SocietyAttention = -8, Happiness = -5 },
				PowerBonus = 3,
				RequiresOriginCategory = "Lineage"
			}
		}
	},

	{
		Id = "domain_opens_on_you",
		Title = "The World Closes",
		Body = "The air changes and the room stops being a room. Someone has opened a domain around you, and it is not going to miss.",
		MinGrade = "Grade 1",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Endure it and counterattack",
				Description = "You took the hit and kept moving through it. It should not have been survivable. It nearly was not.",
				Effects = { Reputation = 12, Health = -30, Fear = 6 },
				PowerBonus = 8
			},
			{
				Text = "Break the barrier from inside",
				Description = "You went for the walls instead of the caster. It collapsed badly, on both of you.",
				Effects = { Reputation = 9, Health = -20, CursedEnergy = -12 },
				PowerBonus = 10
			},
			{
				Text = "Reach the caster before it completes",
				Description = "You crossed the distance in the half second the technique needed and ended it at the source.",
				Effects = { Reputation = 15, Health = -14 },
				PowerBonus = 14
			},
			{
				Text = "[Simple Domain] Refuse the sure hit",
				Description = "Your circle came up and the guaranteed hit stopped being guaranteed. The caster's expression was worth the cursed energy.",
				Effects = { Reputation = 14, CursedEnergy = -16, Health = -6 },
				PowerBonus = 16,
				RequiresSpecificTechnique = "Simple Domain"
			},
			{
				Text = "[Barrier Technique] Answer with a barrier of your own",
				Description = "You raised your own against theirs. Two barriers ground against each other until one gave, and it was not yours.",
				Effects = { Reputation = 13, CursedEnergy = -18 },
				PowerBonus = 15,
				RequiresSpecificTechnique = "Barrier Technique"
			},
			{
				Text = "[Yamashiro] Find the seam",
				Description = "Your family builds these. You knew where the join would be before you looked, and you went straight to it.",
				Effects = { ClanReputation = 9, Reputation = 12, CursedEnergy = -10 },
				PowerBonus = 17,
				RequiresOrigin = "Yamashiro Clan"
			}
		}
	},

	{
		Id = "civilian_asks_for_help",
		Title = "They Asked For You By Name",
		Body = "A civilian tracked you down. Their family has been living with something for two years and no assignment was ever opened. It is not your case and it is not going to become one.",
		MinGrade = "Grade 4",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Handle it off the books",
				Description = "You went that night, unpaid and unlogged. The family sleeps now. You did not report any of it.",
				Effects = { Happiness = 12, Reputation = -3, Health = -10 },
				PowerBonus = 0
			},
			{
				Text = "Escalate it properly and wait",
				Description = "You pushed it up the chain and kept pushing. It took four months and it did eventually get assigned.",
				Effects = { Reputation = 7, SocietyAttention = 4, Happiness = -3 },
				PowerBonus = 0
			},
			{
				Text = "Tell them you cannot",
				Description = "You told them the truth about how the system works. They thanked you for being honest, which was worse.",
				Effects = { Happiness = -11, Reputation = 2 },
				PowerBonus = 0
			},
			{
				Text = "[Civilian] Go, because you know exactly what two years feels like",
				Description = "You grew up in a house nobody came to either. You did not have to think about the answer.",
				Effects = { Happiness = 15, Health = -12, Reputation = -2 },
				PowerBonus = 0,
				RequiresOrigin = "Civilian Family"
			},
			{
				Text = "[Mei Mei] Quote them a rate",
				Description = "You named a price they could actually pay, then did the work properly. Both halves of that mattered to you.",
				Effects = { Money = 1800, Happiness = 5, Reputation = -2 },
				PowerBonus = 0,
				RequiresOrigin = "Mei Mei Lineage"
			}
		}
	},

	{
		Id = "old_sorcerer_dying",
		Title = "The Old One Is Finishing",
		Body = "A sorcerer three times your age is bleeding out against a wall, and they are trying to give you something before they stop.",
		MinGrade = "Grade 3",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Take what they are offering",
				Description = "You took it and they let go. Whatever it was, it is yours now and it came with a weight.",
				Effects = { CursedEnergy = 12, Happiness = -8, Smarts = 4 },
				PowerBonus = 8
			},
			{
				Text = "Refuse and stay with them",
				Description = "You told them to keep it and held their hand instead. They seemed relieved. You will never know what it was.",
				Effects = { Happiness = 6, Reputation = 4, CursedResentment = -3 },
				PowerBonus = 0
			},
			{
				Text = "Get them to a medic first",
				Description = "You carried them out instead of listening. They did not survive the trip, and they spent it trying to speak.",
				Effects = { Health = -12, Happiness = -10, Reputation = 5 },
				PowerBonus = -4
			},
			{
				Text = "[Kamo] Try to hold them together long enough",
				Description = "You worked on the bleeding directly and bought them nine more minutes. They used all nine of them talking.",
				Effects = { Reputation = 10, Health = -8, Smarts = 6 },
				PowerBonus = 6,
				RequiresOrigin = "Kamo Clan"
			},
			{
				Text = "[Brain Transplant] Consider what is being wasted here",
				Description = "You caught yourself assessing them as a container instead of a person, and you were not sure when that had started.",
				Effects = { Smarts = 8, CursedResentment = 6, Happiness = -10 },
				PowerBonus = 5,
				RequiresSpecificTechnique = "Brain Transplant"
			},
			{
				Text = "[Morikage] Sit with them until it is done properly",
				Description = "Your family knows how to be present for this. You did it the way you were taught, and it was not nothing.",
				Effects = { Happiness = 8, ClanReputation = 5, CursedEnergy = 4 },
				PowerBonus = 0,
				RequiresOrigin = "Morikage Clan"
			}
		}
	},

	{
		Id = "your_technique_failed",
		Title = "It Did Not Work",
		Body = "You did everything correctly and your technique did not activate. The curse noticed the pause. So did everyone watching.",
		MinGrade = "Grade 4",
		MaxGrade = "Special Grade",
		Options = {
			{
				Text = "Finish it without the technique",
				Description = "You put it down with your hands and a borrowed blade. It took much longer and nobody who saw it forgot.",
				Effects = { Reputation = 11, Health = -20, Smarts = 3 },
				PowerBonus = 6
			},
			{
				Text = "Withdraw and reassess",
				Description = "You pulled back and worked out what had gone wrong before returning. The delay cost you, and the second attempt held.",
				Effects = { Reputation = 3, Smarts = 7 },
				PowerBonus = 2
			},
			{
				Text = "Force it",
				Description = "You pushed until it fired. It fired. Something in your chest has not felt right since.",
				Effects = { Reputation = 8, Health = -16, CursedEnergy = -14 },
				PowerBonus = 11
			},
			{
				Text = "[Heavenly Restriction] There was never a technique to fail",
				Description = "You have never had one and you have never needed one. You closed the distance and finished it while people were still waiting for a flash of light.",
				Effects = { Reputation = 14, Health = -8, Happiness = 5 },
				PowerBonus = 15,
				RequiresSpecificTechnique = "Heavenly Restriction"
			},
			{
				Text = "[Kusakabe] Fall back on the thing that never fails",
				Description = "Technique is optional. Footwork is not. You did what you have drilled ten thousand times and it worked, as always.",
				Effects = { Reputation = 9, Smarts = 4, Health = -6 },
				PowerBonus = 10,
				RequiresOrigin = "Kusakabe Lineage"
			},
			{
				Text = "[Minor Sorcerer Family] You were always going to need a second plan",
				Description = "Nobody in your family ever had the luxury of relying on one thing. You had already prepared for this.",
				Effects = { Smarts = 6, Reputation = 7, Health = -8 },
				PowerBonus = 8,
				RequiresOrigin = "Minor Sorcerer Family"
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

	for _index, option in ipairs(situation.Options) do
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

		-- Update 28: bloodline choices. Options can now be gated on the exact
		-- origin (a specific clan or lineage) or on its category, so who you
		-- were born as changes what you are able to do in a situation, not
		-- just what the flavour text says about you.
		if ok and option.RequiresOrigin then
			if tostring(stats.Origin or "") ~= option.RequiresOrigin then
				ok = false
			end
		end

		if ok and option.RequiresOriginCategory then
			if tostring(stats.OriginCategory or "") ~= option.RequiresOriginCategory then
				ok = false
			end
		end

		if ok then
			-- Update 28: options are filtered, so position in `available` does not
			-- match position in situation.Options. Carry the source index so the
			-- locale layer can find the right translation for this exact option.
			-- Shallow copy so we never write into the shared Database table.
			local copy = {}
			for k, v in pairs(optionToInsert) do copy[k] = v end
			copy.SourceIndex = _index
			table.insert(available, copy)
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
