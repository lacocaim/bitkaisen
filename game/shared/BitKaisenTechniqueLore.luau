-- ModuleScript: BitKaisenTechniqueLore
-- Location: ReplicatedStorage
--
-- Update 31: an in-world description for every cursed technique in the game.
--
-- This used to be a local table inside TechniqueMasteryPanel, and again, in a shortened
-- form, inside MobileTechniqueMasteryPanel. Two copies meant two things to keep in sync and
-- 27 of 82 techniques written twice, so both panels now read from here instead. Mobile
-- labels auto-size and the panel scrolls, so the full text fits on a phone as it is.
--
-- House style, kept consistent across every entry:
--   * three sentences, written as an in-world reference entry, not as UI copy
--   * no em dashes and no double hyphens anywhere in player-facing text
--   * the last sentence carries the cost, the limit, or the reason it can lose

local BitKaisenTechniqueLore = {}

BitKaisenTechniqueLore.Descriptions = {
	-- Canon, legendary and special grade leaning
	["Limitless"] = "A technique inherited through the Gojo bloodline that manipulates space at the atomic level. The user applies cursed energy to the concept of distance itself, generating infinite convergence that makes direct contact nearly impossible. At its peak, this technique produces an autonomous barrier around the user that deflects anything without conscious thought.",
	["Ten Shadows"] = "A technique that summons and controls up to ten shikigami through the medium of shadows. Each shikigami must be tamed through ritual combat before it can be commanded, a shikigami that defeats its user is lost forever. The technique's power scales with how many shikigami the user controls and how well each one has been mastered.",
	["Copy"] = "A technique that records and reproduces cursed techniques the user has observed. The copied technique is always weaker than the original and degrades further with each copy-of-a-copy. The user can maintain a limited number of active copies at once, and each copy requires CE expenditure proportional to the original's complexity.",
	["Rika Manifestation"] = "A technique born from cursed love, a contract sealed in grief that bound the spirit of a deceased loved one to the user as an immense cursed spirit. The spirit's power dwarfs most conventional techniques, but control is imperfect. At lower mastery, the spirit acts on the user's emotion as much as their intent.",
	["Cursed Spirit Manipulation"] = "A technique that allows the user to consume and control cursed spirits, folding them into a personal army. Each consumed spirit retains its ability, which the user can then deploy. The technique requires actually defeating the spirit first, they cannot be captured at range. A skilled user maintains dozens of spirits simultaneously.",
	["Brain Transplant"] = "A technique that allows the user to transfer their consciousness into a new host body through physical contact and cursed surgery. The technique preserves memories, skills, and cursed energy between transfers. Over time, the user can accumulate techniques from previous hosts, though full integration requires years of use in each body.",
	["Idle Transfiguration"] = "A technique that reshapes the soul directly. The user can alter the form of any soul they make contact with, transforming humans into transfigured humans or manipulating their structure entirely. The resulting constructs obey no normal biological law and are controlled by the user at will.",
	["Mythical Beast Amber"] = "A technique that converts the user's cursed energy directly into electrical discharge, released through the body or driven into a weapon on contact. The user's own nervous system is rebuilt to survive the current, which makes them immune to the output that would kill anyone else holding it. Fully expressed, the technique takes the shape of a lightning beast that fights beside its owner.",
	["Shrine"] = "A technique that generates two intersecting slashes of pure cursed energy at all times, forming a cross-shaped zone of destruction the user can focus or release. The slashes cut through anything they contact regardless of conventional defense, making direct blocking ineffective. The technique's power scales directly with the user's cursed output.",
	["Pumpkin Control"] = "A technique that animates pumpkins and seasonal plant matter with cursed energy, using them as constructs for combat, defense, and field control. The constructs are durable relative to their size and can absorb significant damage before breaking. The technique's ceiling is limited by how many constructs the user can maintain simultaneously.",
	["Star Rage"] = "A technique that assigns virtual mass to the user and to whatever they strike, without changing size or appearance in any visible way. A body carrying weight it was never built for collapses under itself, and a fist carrying that weight lands like something far larger than a fist. The ceiling is entirely mental, the user can only hold so much mass in their head at once.",
	["Comedian"] = "A technique that weaponizes timing, placing a strike exactly on the beat where the target has already decided nothing is coming. The user reads the rhythm of an exchange and inserts an attack into the gap, turning the opponent's own anticipation into the opening. Nobody who has fought a Comedian user can describe the hit that landed, only the pause before it.",

	-- Canon, clan grade
	["Blood Manipulation"] = "A technique that grants complete control over one's own blood. The user can alter blood viscosity, temperature, and trajectory, weaponizing it externally or reinforcing the body from within. Skilled use can stop blood loss entirely, making the user nearly immune to conventional injury in a prolonged fight.",
	["Projection Sorcery"] = "A technique that locks movement into a sequence of pre-planned frames. The user projects their next second of movement across 24 frozen frames, executing it at high speed. Any target caught in the projection is also locked into frames, and anything that doesn't follow a set path within that second is frozen for one second as a penalty.",
	["Construction"] = "A technique that builds objects out of cursed energy at a fixed price per unit of volume. Anything the user can picture clearly enough can be raised in seconds, a wall, a weapon, a cage around someone who was about to run. The limit is cursed energy rather than imagination, and a careless user runs empty in the middle of a fight.",
	["Cursed Speech"] = "A technique that binds cursed energy to spoken commands, forcing reality to comply. The words themselves carry weight, a command delivered with sufficient force becomes physically unavoidable. The technique taxes the user's throat with every use, limiting how often commands can be issued before the body starts to break.",
	["Boogie Woogie"] = "A technique that swaps the position of anything that has been touched with cursed energy. Targets can include people, objects, or the user themselves. The swap is instantaneous and requires no wind-up, making it one of the most unpredictable close-range techniques in practical combat.",
	["Ratio Technique"] = "A technique that divides anything the user touches into a ratio of ten parts. The point that falls on the precise boundary, the exact 6:4 split, becomes a guaranteed critical strike regardless of the target's defenses. Masters can identify this point on a moving target mid-combat.",
	["Straw Doll"] = "A technique that creates cursed connections between the user's nails and a target, bypassing distance entirely. Attacks delivered to a nail or effigy transmit directly to the linked target. The connection persists as long as the cursed link remains active, making it effective against enemies who try to disengage.",
	["Private Pure Love Train"] = "A technique that opens a cursed gambling hall around the user and stakes the outcome of the fight on a single spin. A jackpot buys a window of effectively limitless cursed energy and instant regeneration, a loss leaves the user with nothing but the odds resetting. It belongs to sorcerers willing to hand the result of a battle to chance.",
	["Deadly Sentencing"] = "A technique that convenes a cursed court around the user and their opponent, weighing guilt where a fight would weigh strength. A target found guilty forfeits their cursed technique to the user for as long as the trial stands. The verdict binds regardless of grade, which makes it one of the few techniques a special grade cannot simply overpower.",
	["Ice Formation"] = "A technique that generates and shapes ice out of cursed energy, from thin frost to structures dense enough to stop a full strike. The cold is not ordinary cold, it lowers the temperature of cursed energy itself and slows technique output in anyone standing in it. A skilled user freezes a battlefield into terrain only they know how to cross.",
	["Black Bird Manipulation"] = "A technique that commands crows as a living network of eyes stretched across an entire region. The user sees through every bird at once and can send them to scout, harass, or follow a target for days without rest. The flock's real weapon is information, a user with enough birds knows where a fight will happen before it does.",
	["Tool Manipulation"] = "A technique that moves cursed tools at a distance, letting the user fight with several weapons without holding any of them. Their reach stops being the length of an arm and becomes the size of the room. Every blade in the air is cursed energy the user is not spending on anything else.",
	["Seance Technique"] = "A technique that calls the presence of a dead sorcerer into the user's own body for a limited window. While the seance holds, the user wields the deceased's cursed technique as though it had always been theirs. Every summoning takes something back, and the stronger the spirit the higher the price.",
	["Inverse"] = "A technique that reverses the flow of cursed energy inside the body, turning output that destroys into output that repairs. The user can close their own wounds mid-fight and, at high mastery, extend the healing to another person through direct contact. It is among the hardest disciplines in jujutsu, a single error in the flow burns the body instead of mending it.",
	["Miracle"] = "A technique that bends probability toward the user at the moment it matters most. Strikes that should have connected miss by a finger, footing that should have failed holds long enough. The user gets no say in what form the luck takes, only the certainty that something will fall their way.",
	["Contractual Re-Creation"] = "A technique that restores something destroyed by paying its worth into a binding vow. The user names what they want back and what they are prepared to surrender, and the contract settles the difference. Nothing returns free of charge, and a user who overreaches loses more than they recovered.",
	["Sky Manipulation"] = "A technique that claims the air above a battlefield as ground the user owns. Wind, pressure and falling weight all answer to them inside that space, and an enemy caught in the open is fighting on borrowed terrain. Indoors or underground the technique is close to worthless.",
	["Heavenly Restriction"] = "Not a cursed technique but an inborn contract that strips the body of cursed energy entirely in exchange for physical ability pushed beyond human limits. Speed, strength, and durability reach levels that rival or exceed cursed technique output. The restriction is permanent and cannot be undone.",
	["Disaster Flames"] = "A technique that generates and controls cursed flames of extreme heat and destructive output. The user can produce flames from their body without external fuel, directing them with precision or releasing them in wide-area bursts. The technique has a high CE cost per use but is among the most straightforwardly destructive in the jujutsu world.",

	-- Common and awakened techniques
	["Cloning Technique"] = "A technique that produces short-lived copies of the user out of raw cursed energy. Each clone moves and strikes on its own but comes apart after a single solid hit. Its value is confusion and numbers, never strength.",
	["Rot Technique"] = "A technique that accelerates decay in whatever the user touches, from cloth and steel through to living tissue. The rot spreads outward from the point of contact and does not stop on its own once it has started. Cursed tools break down under it as easily as flesh, which makes an armed opponent the easier target.",
	["Puppet Manipulation"] = "A technique that animates dolls and constructed bodies with cursed energy, moving them at range as extensions of the user. A puppet feels nothing and stops for nothing, letting the user fight without ever stepping into range themselves. Their own body stays fragile, and losing sight of the fight means losing the puppet with it.",
	["Barrier Technique"] = "A technique that raises curtains and veils, walls of cursed energy that decide what may pass and what may not. The terms are set as the barrier goes up, and a well written barrier holds against opponents far stronger than the sorcerer who cast it. Most reach this through years of study rather than through birth, though a few clans still pass the fundamentals down directly.",
	["Simple Domain"] = "Not a domain of one's own but a circle drawn in defense against someone else's. Inside its radius an enemy domain's guaranteed hit stops being guaranteed, and incoming attacks are met on the user's terms instead. It buys time and nothing else, which against a domain user is usually everything.",
	["New Shadow Style"] = "A sword school built for sorcerers who cannot lean on a cursed technique, refined over generations into pure reading of movement. The user tracks an opponent by the shift of their weight rather than by cursed energy, so feints and concealment lose most of their value. Simple Domain is taught alongside it as the defensive half of the same discipline.",
	["Shikigami Technique"] = "A technique that binds a cursed spirit into a servant form the user can call at will. Each shikigami has to be contracted before it will answer, and a contract that breaks cannot be renewed. Unlike the inherited shadow techniques, the user chooses what they bind, so no two practitioners fight the same way.",
	["Hairpin Technique"] = "A technique that stores cursed energy inside a struck surface and detonates it on a delay. The user marks a wall, a floor, or the guard an opponent keeps raising, then triggers the charge once the fight moves back through it. Skilled users fight backwards, setting the trap several exchanges before it matters.",
	["Cursed Tool Reinforcement"] = "A technique that pours cursed energy into a weapon, raising its effective grade for as long as the flow is maintained. An ordinary blade cuts like a cursed tool, and a cursed tool cuts well above its class. The reinforcement drains constantly, so a long fight ends with the weapon back to what it always was.",
	["Cursed Energy Discharge"] = "A technique that releases raw cursed energy in a directed blast, with no shaping and no finesse behind it. It is the first thing most sorcerers learn to do deliberately and the last thing they ever stop using. What it lacks in subtlety it makes up in reliability, it works on anything with a body.",
	["Explosive CE Output"] = "A technique that dumps the user's cursed energy in one uncontrolled burst. The output far exceeds anything they could shape on purpose, at the cost of nearly everything they were holding in reserve. It is a finisher or an escape, never an opening move.",
	["Binding Rope Technique"] = "A technique that spins cursed energy into rope and knots it around a target's limbs or around their technique itself. A bound sorcerer finds their cursed energy running along the rope instead of into their attack. The knots tighten the harder the target pulls, which punishes strength and rewards patience.",
	["Curtain Specialist"] = "A technique built entirely around the curtain, the barrier that hides a space from anyone the caster did not admit. The user can raise one over a whole district in minutes and hold it for hours without emptying themselves. It wins no fights on its own, and no jujutsu operation functions without someone who can do it.",
	["Divergent Fist"] = "Not a cursed technique but a way of throwing a punch, sending a second delayed impact through the target a fraction of a second behind the first. The follow-through carries cursed energy into a guard that has already relaxed. It belongs to fighters with far more physical strength than technical control.",
	["Soul Striking"] = "A technique that lands a blow on the soul instead of the body wrapped around it. Armor, reinforcement and most defensive techniques do nothing against it, because none of them are protecting the thing being hit. Cursed spirits, which are soul and nothing else, come apart under it immediately.",

	-- BitKaisen originals
	["Blood Dominion"] = "A technique that seizes control of blood outside the user's own body, including the blood still inside an opponent. Contact is enough to take hold, so a wounded enemy is already half lost. The jujutsu societies of every era have banned it, and every era has practiced it anyway.",
	["Storm Vessel"] = "A technique that stores atmospheric charge inside the user's body and releases it as directed lightning. The longer the charge is held the more punishing the discharge, and the more damage the user takes from carrying it. Amahara sorcerers spend years training just to survive their own technique.",
	["Mirror Curse"] = "A technique that reflects an incoming attack back down the path it arrived on, carrying the original's full force. The stronger the opponent, the more dangerous striking the user becomes. Reading the incoming technique correctly is the entire skill, a misread mirror shatters and the user takes the hit twice.",
	["Paper Shikigami"] = "A technique that animates paper constructs into functional shikigami. Each construct is single-use and limited in durability, but the technique allows the user to mass-produce scouts, decoys, and support units rapidly. Paper shikigami can carry messages, relay scouting data, or detonate on contact.",
	["Iron Bloom"] = "A technique that grows iron out of cursed energy in branching, flowering structures. The blooms can be raised as cover, driven forward as spears, or opened inside a wound that has already been made. Everything the technique grows stays exactly where it grew until the user takes it back.",
	["Shadow Thread"] = "A technique that draws thread out of shadow and stitches it between two fixed points. Whatever the thread connects can be pulled, held in place, or cut along the line it runs. In darkness the threads are effectively invisible, which is why Kurogiri sorcerers fight almost exclusively at night.",
	["Soul Ledger"] = "A technique that records what the user has taken and what they still owe, then enforces the balance without being asked. A debt paid back to the ledger returns as cursed energy, a debt left standing collects itself out of the user. It rewards a sorcerer who keeps an honest account and ruins one who does not.",
	["Ash Binding"] = "A technique that binds what has already burned, holding ash in the shape it held while it lived. The bound form does not breathe or bleed and absorbs far more punishment than the body it copies. Everything it raises collapses the instant the user's concentration breaks.",
	["Frost Burial"] = "A technique that drops a target's temperature from the inside until movement stops entirely. The freeze travels along cursed energy pathways rather than through flesh, so a sorcerer channeling a technique freezes fastest of all. A fully buried target can be thawed, but almost never in time.",
	["Starfall Dice"] = "A technique that casts cursed dice and applies whatever they land on to the next exchange. Results run from a small edge to a strike that closes the fight outright, and the user has no say in which. Sorcerers who build their style around it either die young or retire wealthy.",
	["Static Crown"] = "A technique that rings the user's head with cursed static that disrupts thought at close range. Opponents inside the ring lose the thread of their own technique halfway through activating it. The user is not exempt, and long exposure leaves them as scattered as the people they used it on.",
	["Bone Script"] = "A technique that carves cursed writing into bone, the user's own or somebody else's, and holds an effect there until it is read out. Anything written in advance fires the instant it is spoken, letting the user prepare far more than a fight leaves time for. The carving itself takes hours, so the technique belongs to sorcerers who plan.",
	["Glass Coffin"] = "A technique that seals a target inside cursed glass exactly where they stand. The coffin holds against force in proportion to what the user spent raising it, and nothing inside it ages while it stands. Sorcerers who cannot be killed are usually just put away like this instead.",
	["Smoke Threading"] = "A technique that pulls smoke into fine threads and pins them at fixed points in the air. The threads cut, bind, and mark exactly where an enemy has passed through them. Any room the user has been standing in for a minute is already full of them.",
	["Ink Binding"] = "A technique that writes cursed ink onto a surface or a body and makes the writing true for as long as it holds. A word set on an opponent's arm can keep that arm from lifting. Ink runs, smears and washes away, which is the only reason the technique is survivable at all.",
	["Moon Thread"] = "A technique that draws a single thread of pale light between the user and one target and keeps it taut at any distance. The user can travel along it, pull against it, or sever it and take a piece of whatever it was fixed to. Only one thread exists at a time, so choosing the target is the whole technique.",
	["Echo Step"] = "A technique that leaves a cursed echo of the user standing where they were a second ago. Attacks aimed at the echo hit nothing and tell the user exactly where the attacker is standing. The echo cannot act, it only stands there and gets hit.",
	["Grave Bloom"] = "A technique that generates cursed flowers from accumulated death energy. The blooms absorb cursed energy from their surroundings and can be detonated, releasing the stored energy as a purifying blast. The technique is passive in accumulation but devastating in release.",
	["Thread Manipulation"] = "A technique that creates and controls threads of condensed cursed energy. The threads are invisible to those without cursed energy sensitivity and strong enough to cut through flesh and bone at sufficient mastery. The user can set threads in advance, binding spaces and creating invisible traps that trigger on contact.",
	["Mirror Step"] = "A technique that allows the user to enter and travel through reflective surfaces, emerging from any other reflective surface within range. At higher mastery, the user can pull targets into mirror-space and control what reflections show. The technique is nearly undetectable in environments with multiple reflective surfaces.",
	["Static Binding"] = "A technique that generates cursed static, a field of disruptive energy that interferes with cursed technique output and motor control. Targets caught in the field find their technique activation delayed and their movements slightly desynchronized. At high mastery, the field can lock a target's technique entirely for a short window.",
	["Glass Veil"] = "A technique that bends light and cursed perception, making the user difficult to track visually or sense with cursed energy. The user does not become truly invisible, they become inconsistent, appearing in the wrong position or failing to register entirely for a split second. That gap is enough.",
	["Bone Forge"] = "A technique that hardens and shapes the user's own bone matter into weapons and tools. The extracted bone is denser than steel at peak output and can be regrown given enough cursed energy. The technique's biggest strength is speed, a weapon can be produced in under a second and replaced just as fast.",
	["Shadow Stitch"] = "A technique that anchors a target through their shadow, restricting movement as long as the shadow-link holds. If the target's shadow touches the user's or a surface the user has marked, the stitch can be applied from a distance. Breaking the stitch requires enough force to physically tear the cursed connection.",
	["Echo Pulse"] = "A technique that reads cursed energy through vibration and sound. The user can detect active techniques in a wide radius and distinguish their signatures, functioning as a living cursed energy scanner. At high mastery, the user can send a pulse that temporarily disrupts technique activation in a short radius.",
	["Crow Funeral"] = "A technique that controls cursed crows as scouting, combat, and intimidation instruments. The crows function as extensions of the user's senses and can apply cursed energy directly on contact. A large enough flock creates an oppressive presence that degrades enemy morale and blocks line of sight.",
	["Threaded Verdict"] = "A technique that wraps an opponent in cursed thread and holds the binding until a judgement is spoken aloud. Every accusation the user can actually support draws the threads tighter. A verdict delivered in full leaves the target unable to use their technique for the rest of the encounter.",
	["Mirror Garden"] = "A technique that fills a space with standing mirrors, every one of them a position the user could be occupying. The opponent ends up fighting a room of reflections with no way to tell which one is about to move. Breaking all of them is possible and takes more time than most fights allow.",
	["Static Execution"] = "A technique that builds charge across an entire exchange and releases it in one strike aimed at whatever the user has been touching. Blocking counts as contact, so a defensive opponent spends the fight charging the technique that kills them. It fires once and leaves the user completely empty.",
	["Grave Lantern"] = "A technique that lights a cursed lantern showing the dead in a space and what put them there. Sorcerers use it to read a site before deciding how to walk into it. The light also draws whatever is still present, so reading a room announces the reader.",
	["Ashen Step"] = "A technique that turns the user to ash for the length of a single stride, letting attacks and terrain pass straight through them. Reforming costs cursed energy in proportion to how far the step carried. Chained too many times in a row, the user comes back missing something.",
	["Blood Tax"] = "A technique that takes blood as payment and gives it back as power, the user's own or somebody else's. Blood drawn from a wound the user made returns at full value, blood spent out of their own body returns at a loss. It makes long fights favor whoever is bleeding less.",
	["Curtain Maw"] = "A technique that raises a curtain shaped to close rather than to hide, folding a space shut around whatever is inside it. The barrier is not a wall but a mouth, and it keeps tightening for as long as it stands. Anyone who cannot break a curtain from the inside does not come out.",
	["Cursed Pulse Radar"] = "A technique that sends out a low cursed pulse and reads whatever comes back. The user learns the position, rough grade and heading of everything carrying cursed energy in range. It contributes nothing to a fight, and it keeps sorcerers alive on the way to one.",
	["Vow Chain"] = "A technique that binds two parties in a visible chain of cursed energy and holds both of them to what was agreed. Neither side can break the terms while the chain stands, and breaking the chain costs the one who broke it far more than keeping it would have. Most sorcerers who learn this end up using it on themselves.",
	["Shatter Palm"] = "A technique that concentrates cursed energy into the palm and releases it on contact as a fracturing shock. The force travels through guards and armor into whatever is standing behind them. It is simple and short-ranged, and one of the few common techniques that keeps scaling all the way up.",
}

-- The mastery screen shows a second, shorter line under the technique name: what you are
-- learning and what climbing the mastery track actually buys you. The same 55 techniques
-- that had no description also had no flavor line, so every one of them fell back to the
-- same generic sentence. Both tables are complete now.
--
-- House style here is fixed and deliberately repetitive, it reads as a training note:
--   "You are learning to <verb>. Higher mastery improves <the choices it unlocks>."
BitKaisenTechniqueLore.Flavor = {
	-- Canon, legendary and special grade leaning
	["Limitless"] = "You are learning to control space, distance, and cursed energy precision. Higher mastery improves defense, rescue choices, mission safety, and promotion pressure.",
	["Ten Shadows"] = "You are learning to command shadows, shikigami, and cursed space. Higher mastery improves scouting, rescue choices, and mission control.",
	["Copy"] = "You are learning to understand and reproduce cursed techniques. Higher mastery improves flexibility and special mission responses.",
	["Rika Manifestation"] = "You are learning to control overwhelming cursed presence. Higher mastery improves combat pressure and dangerous rescue outcomes.",
	["Cursed Spirit Manipulation"] = "You are learning to command curses as weapons. Higher mastery improves curse-control choices and mission domination.",
	["Brain Transplant"] = "You are learning to preserve your will through stolen bodies and inherited memories. Higher mastery improves host control, combat stability, and forbidden relationship actions.",
	["Idle Transfiguration"] = "You are learning to understand the shape of the soul. Higher mastery improves terrifying choices, curse analysis, and high-risk mission options.",
	["Mythical Beast Amber"] = "You are learning to hold lightning inside your own body without dying of it. Higher mastery improves burst damage, duel challenges, and reckless combat choices.",
	["Shrine"] = "You are learning to turn slashes and cursed output into clean destruction. Higher mastery improves direct combat pressure and ruthless mission outcomes.",
	["Pumpkin Control"] = "You are learning to animate pumpkins, vines, and heavy seasonal constructs. Higher mastery improves field control, defense, and strange pressure-based outcomes.",
	["Star Rage"] = "You are learning to give weight to things that never had it. Higher mastery improves raw impact, crowd control, and options in fights you should lose.",
	["Comedian"] = "You are learning to strike on the beat nobody is watching. Higher mastery improves timing-based choices, ambush outcomes, and social misdirection.",

	-- Canon, clan grade
	["Blood Manipulation"] = "You are learning to weaponize blood without destroying your own body. Higher mastery improves risky mission choices and reduces the cost of dangerous actions.",
	["Projection Sorcery"] = "You are learning to move through moments like frames. Higher mastery improves speed-based choices and clean mission execution.",
	["Construction"] = "You are learning to build with cursed energy at a fixed price. Higher mastery improves defense, rescue setups, and resource-efficient mission choices.",
	["Cursed Speech"] = "You are learning to force cursed commands into reality. Higher mastery improves social pressure, mission control, and command-based choices.",
	["Boogie Woogie"] = "You are learning to control positioning and misdirection. Higher mastery improves escape choices, rescue choices, and impossible saves.",
	["Ratio Technique"] = "You are learning to identify weak points under pressure. Higher mastery improves precision, smarter mission choices, and critical outcomes.",
	["Straw Doll"] = "You are learning to strike curses through links and residue. Higher mastery improves investigation, precision, and indirect exorcism choices.",
	["Private Pure Love Train"] = "You are learning to stake a fight on odds nobody else would take. Higher mastery improves gamble choices, comeback outcomes, and cursed energy recovery.",
	["Deadly Sentencing"] = "You are learning to weigh guilt instead of strength. Higher mastery improves judgement choices, interrogation, and outcomes against stronger opponents.",
	["Ice Formation"] = "You are learning to freeze cursed energy itself, not just water. Higher mastery improves containment, terrain control, and suppression choices.",
	["Black Bird Manipulation"] = "You are learning to watch a whole region through borrowed eyes. Higher mastery improves scouting, information gathering, and paid mission choices.",
	["Tool Manipulation"] = "You are learning to fight with weapons you never have to hold. Higher mastery improves cursed tool interactions, reach, and multi-target choices.",
	["Seance Technique"] = "You are learning to borrow the dead and what they knew. Higher mastery improves investigation, inherited technique options, and choices involving the deceased.",
	["Inverse"] = "You are learning to turn destructive output into healing. Higher mastery improves survival, recovery after missions, and saving other people.",
	["Miracle"] = "You are learning to let probability lean your way. Higher mastery improves lucky outcomes, escape choices, and survival against bad odds.",
	["Contractual Re-Creation"] = "You are learning to buy back what you lost with a binding vow. Higher mastery improves vow choices, recovery of lost things, and high-price outcomes.",
	["Sky Manipulation"] = "You are learning to own the air above a fight. Higher mastery improves outdoor mission choices, mobility, and pressure over open ground.",
	["Heavenly Restriction"] = "You do not rely on a normal cursed technique. Your body itself becomes the weapon. Higher mastery represents control, discipline, timing, and raw physical dominance.",
	["Disaster Flames"] = "You are learning to control destructive cursed flame. Higher mastery improves overwhelming force options and dangerous curse suppression.",

	-- Common and awakened techniques
	["Cloning Technique"] = "You are learning to be in more places than one. Higher mastery improves distraction, escape, and multi-task mission choices.",
	["Rot Technique"] = "You are learning to hurry decay along. Higher mastery improves attrition choices, cursed tool destruction, and grim mission outcomes.",
	["Puppet Manipulation"] = "You are learning to fight through bodies that are not yours. Higher mastery improves safe engagement, scouting, and indirect mission choices.",
	["Barrier Technique"] = "You are learning to decide what a space will let through. Higher mastery improves containment, evacuation, and support choices on missions.",
	["Simple Domain"] = "You are learning to hold a circle against someone else's domain. Higher mastery improves survival, defensive choices, and outcomes against special grades.",
	["New Shadow Style"] = "You are learning to read weight and movement instead of cursed energy. Higher mastery improves swordplay, counters, and choices against concealment.",
	["Shikigami Technique"] = "You are learning to contract spirits into servants that answer. Higher mastery improves scouting, support, and summoning choices.",
	["Hairpin Technique"] = "You are learning to leave charges where the fight will come back through. Higher mastery improves trap setups, ambush outcomes, and prepared mission choices.",
	["Cursed Tool Reinforcement"] = "You are learning to lift a weapon above its grade. Higher mastery improves cursed tool damage, forging outcomes, and armed mission choices.",
	["Cursed Energy Discharge"] = "You are learning to put raw output exactly where you want it. Higher mastery improves direct damage and reliable mission choices.",
	["Explosive CE Output"] = "You are learning to spend everything at once. Higher mastery improves finisher choices, desperate escapes, and last stand outcomes.",
	["Binding Rope Technique"] = "You are learning to tie down cursed energy along with the limbs. Higher mastery improves capture, restraint, and anti-technique choices.",
	["Curtain Specialist"] = "You are learning to hide a whole district from the people standing in it. Higher mastery improves concealment, civilian safety, and support mission choices.",
	["Divergent Fist"] = "You are learning to land twice with a single punch. Higher mastery improves unarmed combat and pressure against guarded opponents.",
	["Soul Striking"] = "You are learning to hit past the body. Higher mastery improves damage against curses, defense-ignoring choices, and exorcism outcomes.",

	-- BitKaisen originals
	["Blood Dominion"] = "You are learning to command blood that was never yours. Higher mastery improves control over wounded enemies, forbidden choices, and the risk that follows them.",
	["Storm Vessel"] = "You are learning to carry a storm and survive holding it. Higher mastery improves burst damage, charged choices, and outcomes that reward patience.",
	["Mirror Curse"] = "You are learning to send an attack back the way it came. Higher mastery improves counters, defense, and outcomes against stronger opponents.",
	["Paper Shikigami"] = "You are learning to use paper constructs for scouting and support. Higher mastery improves tracking, surveillance, and indirect mission choices.",
	["Iron Bloom"] = "You are learning to grow iron exactly where you need it. Higher mastery improves defense, terrain control, and armed mission choices.",
	["Shadow Thread"] = "You are learning to stitch shadow between two points. Higher mastery improves restraint, night mission choices, and pulling people out of danger.",
	["Soul Ledger"] = "You are learning to keep an account the world collects on for you. Higher mastery improves vow choices, debt outcomes, and cursed energy recovery.",
	["Ash Binding"] = "You are learning to hold shape in what has already burned. Higher mastery improves construct support, defensive choices, and grim mission options.",
	["Frost Burial"] = "You are learning to stop a body from the inside. Higher mastery improves containment, capture, and suppression of enemy techniques.",
	["Starfall Dice"] = "You are learning to let the dice settle the exchange. Higher mastery improves gamble outcomes, swing results, and reckless mission choices.",
	["Static Crown"] = "You are learning to scatter thought at close range. Higher mastery improves technique disruption, interrogation, and close quarters choices.",
	["Bone Script"] = "You are learning to write an effect down and keep it there. Higher mastery improves prepared choices, ritual outcomes, and missions you get to plan.",
	["Glass Coffin"] = "You are learning to put a problem away instead of killing it. Higher mastery improves sealing, capture, and long term containment choices.",
	["Smoke Threading"] = "You are learning to fill a room with edges nobody can see. Higher mastery improves indoor control, ambush outcomes, and tracking choices.",
	["Ink Binding"] = "You are learning to write something true onto a body. Higher mastery improves restraint, curse marking, and precise support choices.",
	["Moon Thread"] = "You are learning to fix one line between yourself and one target. Higher mastery improves pursuit, single target outcomes, and rescue choices.",
	["Echo Step"] = "You are learning to leave yourself behind for a moment. Higher mastery improves evasion, counter setups, and survival choices.",
	["Grave Bloom"] = "You are learning to bury cursed energy through blooming death. Higher mastery improves exorcism, emotional resistance, and curse-cleansing choices.",
	["Thread Manipulation"] = "You are learning to bind, pull, and control targets from a distance. Higher mastery improves rescue and restraint options.",
	["Mirror Step"] = "You are learning to move through reflections and false openings. Higher mastery improves illusion-breaking and scouting choices.",
	["Static Binding"] = "You are learning to lock movement and disrupt energy through cursed static. Higher mastery improves containment and anti-recording choices.",
	["Glass Veil"] = "You are learning to bend visibility, reflection, and cursed perception. Higher mastery improves deception, escape, and concealment choices.",
	["Bone Forge"] = "You are learning to shape cursed bone into tools and weapons. Higher mastery improves cursed tool interactions and survival choices.",
	["Shadow Stitch"] = "You are learning to pin targets through their shadows. Higher mastery improves restraint, trap, and illusion-control choices.",
	["Echo Pulse"] = "You are learning to read cursed energy through sound and vibration. Higher mastery improves detection and investigation choices.",
	["Crow Funeral"] = "You are learning to use cursed birds, omen pressure, and swarm tactics. Higher mastery improves surveillance, intimidation, and mission disruption choices.",
	["Threaded Verdict"] = "You are learning to bind an opponent to what they have already done. Higher mastery improves judgement choices, interrogation, and technique suppression.",
	["Mirror Garden"] = "You are learning to fill a space with every place you might be. Higher mastery improves deception, defensive choices, and control of enclosed fights.",
	["Static Execution"] = "You are learning to charge an entire fight into one strike. Higher mastery improves finisher outcomes and choices that reward drawing a fight out.",
	["Grave Lantern"] = "You are learning to read what a place still remembers. Higher mastery improves investigation, site preparation, and choices involving the dead.",
	["Ashen Step"] = "You are learning to come apart for the length of a stride. Higher mastery improves evasion, escape choices, and survival in bad terrain.",
	["Blood Tax"] = "You are learning to charge blood as a price and collect on it. Higher mastery improves attrition outcomes, drain choices, and long fight options.",
	["Curtain Maw"] = "You are learning to close a barrier instead of hiding behind it. Higher mastery improves capture, containment, and choices against anyone trying to run.",
	["Cursed Pulse Radar"] = "You are learning to ask a room what is standing in it. Higher mastery improves detection, investigation, and knowing which fights to walk away from.",
	["Vow Chain"] = "You are learning to hold two people to what was agreed. Higher mastery improves vow choices, negotiation, and outcomes built on binding terms.",
	["Shatter Palm"] = "You are learning to break what is standing behind the guard. Higher mastery improves unarmed damage and choices against defended opponents.",
}

-- Returns the description for a technique, or nil when the technique has none.
function BitKaisenTechniqueLore.Get(techniqueName): string?
	return BitKaisenTechniqueLore.Descriptions[tostring(techniqueName or "")]
end

-- Returns the mastery flavor line for a technique, or nil when the technique has none.
function BitKaisenTechniqueLore.GetFlavor(techniqueName): string?
	return BitKaisenTechniqueLore.Flavor[tostring(techniqueName or "")]
end

return BitKaisenTechniqueLore
