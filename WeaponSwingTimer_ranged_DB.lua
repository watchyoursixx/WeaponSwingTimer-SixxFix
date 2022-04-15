local addon_name, addon_data = ...

--- define addon structure from the above local variable
addon_data.ranged_DB = {}
--- declare array for ranks of all abilities, cast times, cooldown, based on spell ID
addon_data.ranged_DB.item_ids = {
	[1046] = {base_speed = 1.9},    -- Deprecated Light Blunderbuss
	[1047] = {base_speed = 2.4},    -- Deprecated Heavy Blunderbuss
	[2098] = {base_speed = 2.3},    -- Double-barreled Shotgun
	[2099] = {base_speed = 2.9},    -- Dwarven Hand Cannon
	[2100] = {base_speed = 1.5},    -- Precisely Calibrated Boomstick
	[2504] = {base_speed = 2.3},    -- Worn Shortbow
	[2505] = {base_speed = 2},    -- Polished Shortbow
	[2506] = {base_speed = 2.1},    -- Hornwood Recurve Bow
	[2507] = {base_speed = 2.6},    -- Laminated Recurve Bow
	[2508] = {base_speed = 2.3},    -- Old Blunderbuss
	[2509] = {base_speed = 2.2},    -- Ornate Blunderbuss
	[2510] = {base_speed = 2.2},    -- Solid Blunderbuss
	[2511] = {base_speed = 2.1},    -- Hunter's Boomstick
	[2550] = {base_speed = 2},    -- Monster - Bow, Short
	[2551] = {base_speed = 2},    -- Monster - Crossbow
	[2552] = {base_speed = 2},    -- Monster - Gun
	[2773] = {base_speed = 2.3},    -- Cracked Shortbow
	[2774] = {base_speed = 2.4},    -- Rust-covered Blunderbuss
	[2777] = {base_speed = 1.8},    -- Feeble Shortbow
	[2778] = {base_speed = 2.2},    -- Cheap Blunderbuss
	[2780] = {base_speed = 1.7},    -- Light Hunting Bow
	[2781] = {base_speed = 2.2},    -- Dirty Blunderbuss
	[2782] = {base_speed = 2.4},    -- Mishandled Recurve Bow
	[2783] = {base_speed = 2.1},    -- Shoddy Blunderbuss
	[2785] = {base_speed = 2.8},    -- Stiff Recurve Bow
	[2786] = {base_speed = 2},    -- Oiled Blunderbuss
	[2824] = {base_speed = 1.6},    -- Hurricane
	[2825] = {base_speed = 2.7},    -- Bow of Searing Arrows
	[2903] = {base_speed = 2.3},    -- Daryl's Hunting Bow
	[2904] = {base_speed = 2.5},    -- Daryl's Hunting Rifle
	[3021] = {base_speed = 2.7},    -- Ranger Bow
	[3023] = {base_speed = 2.5},    -- Large Bore Blunderbuss
	[3024] = {base_speed = 2.7},    -- BKP 2700 "Enforcer"
	[3025] = {base_speed = 2.1},    -- BKP 42 "Ultra"
	[3026] = {base_speed = 2.2},    -- Reinforced Bow
	[3027] = {base_speed = 2.4},    -- Heavy Recurve Bow
	[3028] = {base_speed = 2.3},    -- Longbow
	[3036] = {base_speed = 2.5},    -- Heavy Shortbow
	[3037] = {base_speed = 1.8},    -- Whipwood Recurve Bow
	[3039] = {base_speed = 1.9},    -- Short Ash Bow
	[3040] = {base_speed = 1.8},    -- Hunter's Muzzle Loader
	[3041] = {base_speed = 2.8},    -- "Mage-Eye" Blunderbuss
	[3042] = {base_speed = 1.7},    -- BKP "Sparrow" Smallbore
	[3078] = {base_speed = 1.8},    -- Naga Heartpiercer
	[3079] = {base_speed = 1.9},    -- Skorn's Rifle
	[3430] = {base_speed = 3},    -- Sniper Rifle
	[3493] = {base_speed = 2.9},    -- Raptor's End
	[3567] = {base_speed = 1.9},    -- Dwarven Fishing Pole
	[3742] = {base_speed = 2.6},    -- Bow of Plunder
	[3778] = {base_speed = 2.5},    -- Taut Compound Bow
	[3780] = {base_speed = 2.6},    -- Long-barreled Musket
	[4025] = {base_speed = 1.8},    -- Balanced Long Bow
	[4026] = {base_speed = 2.8},    -- Sentinel Musket
	[4086] = {base_speed = 1.8},    -- Flash Rifle
	[4087] = {base_speed = 1.9},    -- Trueshot Bow
	[4089] = {base_speed = 2.3},    -- Ricochet Blunderbuss
	[4110] = {base_speed = 2.9},    -- Master Hunter's Bow
	[4111] = {base_speed = 2.9},    -- Master Hunter's Rifle
	[4127] = {base_speed = 1.9},    -- Shrapnel Blaster
	[4362] = {base_speed = 2.3},    -- Rough Boomstick
	[4369] = {base_speed = 2.6},    -- Deadly Blunderbuss
	[4372] = {base_speed = 1.8},    -- Lovingly Crafted Boomstick
	[4379] = {base_speed = 2.7},    -- Silver-plated Shotgun
	[4383] = {base_speed = 1.7},    -- Moonsight Rifle
	[4474] = {base_speed = 1.9},    -- Ravenwood Bow
	[4547] = {base_speed = 1.3},    -- Gnomish Zapper
	[4576] = {base_speed = 1.7},    -- Light Bow
	[4577] = {base_speed = 2},    -- Compact Shotgun
	[4763] = {base_speed = 2.7},    -- Blackwood Recurve Bow
	[4899] = {base_speed = 3},    -- Test Crossbow
	[4902] = {base_speed = 1.5},    -- Deprecated Apprentice Wand
	[4912] = {base_speed = 1.2},    -- Test Wand JChow
	[4931] = {base_speed = 2},    -- Hickory Shortbow
	[4985] = {base_speed = 1.2},    -- Test Proc Wand
	[5069] = {base_speed = 1.5},    -- Fire Wand
	[5071] = {base_speed = 1.4},    -- Shadow Wand
	[5092] = {base_speed = 1.5},    -- Charred Razormane Wand
	[5198] = {base_speed = 1.3},    -- Cookie's Stirring Rod
	[5207] = {base_speed = 1.4},    -- Opaque Wand
	[5208] = {base_speed = 1.6},    -- Smoldering Wand
	[5209] = {base_speed = 1.8},    -- Gloom Wand
	[5210] = {base_speed = 1.4},    -- Burning Wand
	[5211] = {base_speed = 1.7},    -- Dusk Wand
	[5212] = {base_speed = 1.5},    -- Blazing Wand
	[5213] = {base_speed = 1.3},    -- Scorching Wand
	[5214] = {base_speed = 1.3},    -- Wand of Eventide
	[5215] = {base_speed = 1.5},    -- Ember Wand
	[5216] = {base_speed = 1.5},    -- Umbral Wand
	[5235] = {base_speed = 1.8},    -- Alchemist's Wand
	[5236] = {base_speed = 1.6},    -- Combustible Wand
	[5238] = {base_speed = 1.7},    -- Pitchwood Wand
	[5239] = {base_speed = 1.6},    -- Blackbone Wand
	[5240] = {base_speed = 1.3},    -- Torchlight Wand
	[5241] = {base_speed = 1.8},    -- Dwarven Flamestick
	[5242] = {base_speed = 1.4},    -- Cinder Wand
	[5243] = {base_speed = 1.7},    -- Firebelcher
	[5244] = {base_speed = 1.2},    -- Consecrated Wand
	[5245] = {base_speed = 1.8},    -- Summoner's Wand
	[5246] = {base_speed = 1.9},    -- Excavation Rod
	[5247] = {base_speed = 1.9},    -- Rod of Sorrow
	[5248] = {base_speed = 1.3},    -- Flash Wand
	[5249] = {base_speed = 1.3},    -- Burning Sliver
	[5250] = {base_speed = 1.8},    -- Charred Wand
	[5252] = {base_speed = 1.5},    -- Wand of Decay
	[5253] = {base_speed = 2},    -- Goblin Igniter
	[5258] = {base_speed = 2},    -- Monster - Bow, Black
	[5259] = {base_speed = 2},    -- Monster - Bow, Red
	[5260] = {base_speed = 2},    -- Monster - Bow, Brown
	[5261] = {base_speed = 2},    -- Monster - Bow, Gray
	[5262] = {base_speed = 2},    -- Monster - Bow, Dark Brown
	[5309] = {base_speed = 2.3},    -- Privateer Musket
	[5326] = {base_speed = 1.9},    -- Flaring Baton
	[5346] = {base_speed = 1.9},    -- Orcish Battle Bow
	[5347] = {base_speed = 1.5},    -- Pestilent Wand
	[5356] = {base_speed = 1.6},    -- Branding Rod
	[5546] = {base_speed = 0.5},    -- Fast Test Crossbow
	[5548] = {base_speed = 0.5},    -- Fast Test Bow
	[5550] = {base_speed = 0.5},    -- Fast Test Gun
	[5560] = {base_speed = 0.5},    -- Fast Test Wand
	[5596] = {base_speed = 2.1},    -- Ashwood Bow
	[5604] = {base_speed = 1.6},    -- Elven Wand
	[5748] = {base_speed = 2.2},    -- Centaur Longbow
	[5817] = {base_speed = 2.7},    -- Lunaris Bow
	[5818] = {base_speed = 1.8},    -- Moonbeam Wand
	[5856] = {base_speed = 2},    -- Monster - Throwing Axe
	[5870] = {base_speed = 2},    -- Monster - Throwing Spear
	[6088] = {base_speed = 2},    -- Monster - Torch, Ranged
	[6230] = {base_speed = 2},    -- Monster - Wand, Basic
	[6231] = {base_speed = 2},    -- Monster - Wand, Jeweled - Green
	[6315] = {base_speed = 3.4},    -- Steelarrow Crossbow
	[6469] = {base_speed = 2.4},    -- Venomstrike
	[6677] = {base_speed = 1.7},    -- Spellcrafter Wand
	[6696] = {base_speed = 1.7},    -- Nightstalker Bow
	[6729] = {base_speed = 1.5},    -- Fizzle's Zippy Lighter
	[6739] = {base_speed = 2.3},    -- Cliffrunner's Aim
	[6797] = {base_speed = 1.7},    -- Eyepoker
	[6798] = {base_speed = 2.8},    -- Blasting Hackbut
	[6806] = {base_speed = 1.4},    -- Dancing Flame
	[6886] = {base_speed = 2},    -- Monster - Throwing Knife
	[7001] = {base_speed = 1.5},    -- Gravestone Scepter
	[7513] = {base_speed = 1.4},    -- Ragefire Wand
	[7514] = {base_speed = 1.6},    -- Icefury Wand
	[7607] = {base_speed = 1.8},    -- Sable Wand
	[7708] = {base_speed = 1.4},    -- Necrotic Wand
	[7729] = {base_speed = 2.3},    -- Chesterfall Musket
	[8071] = {base_speed = 1.7},    -- Sizzle Stick
	[8179] = {base_speed = 2},    -- Cadet's Bow
	[8180] = {base_speed = 2.6},    -- Hunting Bow
	[8181] = {base_speed = 2.7},    -- Hunting Rifle
	[8182] = {base_speed = 2.6},    -- Pellet Rifle
	[8183] = {base_speed = 2.6},    -- Precision Bow
	[8184] = {base_speed = 1.5},    -- Firestarter
	[8186] = {base_speed = 1.7},    -- Dire Wand
	[8188] = {base_speed = 2.1},    -- Explosive Shotgun
	[9381] = {base_speed = 1.7},    -- Earthen Rod
	[9400] = {base_speed = 2.3},    -- Baelog's Shortbow
	[9412] = {base_speed = 2.6},    -- Galgann's Fireblaster
	[9422] = {base_speed = 2.9},    -- Shadowforge Bushmaster
	[9426] = {base_speed = 2.7},    -- Monolithic Bow
	[9456] = {base_speed = 2.9},    -- Glass Shooter
	[9483] = {base_speed = 1.8},    -- Flaming Incinerator
	[9487] = {base_speed = 2.3},    -- Hi-tech Supergun
	[9489] = {base_speed = 1.4},    -- Gyromatic Icemaker
	[9654] = {base_speed = 1.8},    -- Cairnstone Sliver
	[10508] = {base_speed = 2.9},    -- Mithril Blunderbuss
	[10510] = {base_speed = 2.9},    -- Mithril Heavy-bore Rifle
	[10567] = {base_speed = 2.8},    -- Quillshooter
	[10572] = {base_speed = 1.3},    -- Freezing Shard
	[10624] = {base_speed = 2.8},    -- Stinging Bow
	[10704] = {base_speed = 1.4},    -- Chillnail Splinter
	[10766] = {base_speed = 1.6},    -- Plaguerot Sprig
	[10836] = {base_speed = 1.3},    -- Rod of Corrosion
	[11021] = {base_speed = 2},    -- Monster - Big Sniper Gun
	[11263] = {base_speed = 1.5},    -- Nether Force Wand
	[11287] = {base_speed = 1.5},    -- Lesser Magic Wand
	[11288] = {base_speed = 1.8},    -- Greater Magic Wand
	[11289] = {base_speed = 1.3},    -- Lesser Mystic Wand
	[11290] = {base_speed = 2},    -- Greater Mystic Wand
	[11303] = {base_speed = 1.7},    -- Fine Shortbow
	[11304] = {base_speed = 2.7},    -- Fine Longbow
	[11305] = {base_speed = 1.9},    -- Dense Shortbow
	[11306] = {base_speed = 2.2},    -- Sturdy Recurve
	[11307] = {base_speed = 2.8},    -- Massive Longbow
	[11308] = {base_speed = 2},    -- Sylvan Shortbow
	[11628] = {base_speed = 1.8},    -- Houndmaster's Bow
	[11629] = {base_speed = 2.3},    -- Houndmaster's Rifle
	[11748] = {base_speed = 1.8},    -- Pyric Caduceus
	[11860] = {base_speed = 1.5},    -- Charged Lightning Rod
	[12296] = {base_speed = 1.8},    -- Spark of the People's Militia
	[12446] = {base_speed = 2.7},    -- Anvilmar Musket
	[12447] = {base_speed = 2.3},    -- Thistlewood Bow
	[12448] = {base_speed = 1.9},    -- Light Hunting Rifle
	[12449] = {base_speed = 2.7},    -- Primitive Bow
	[12468] = {base_speed = 0.5},    -- Chilton Wand
	[12523] = {base_speed = 2},    -- Monster - Gun, Silver Musket
	[12605] = {base_speed = 1.4},    -- Serpentine Skuller
	[12651] = {base_speed = 3.2},    -- Blackcrow
	[12653] = {base_speed = 2.2},    -- Riphook
	[12941] = {base_speed = 2},    -- Monster - Wand, Jeweled - B02 Red
	[12984] = {base_speed = 1.6},    -- Skycaller
	[13004] = {base_speed = 1.4},    -- Torch of Austen
	[13019] = {base_speed = 1.8},    -- Harpyclaw Short Bow
	[13020] = {base_speed = 2.1},    -- Skystriker Bow
	[13021] = {base_speed = 2},    -- Needle Threader
	[13022] = {base_speed = 2.7},    -- Gryphonwing Long Bow
	[13023] = {base_speed = 1.8},    -- Eaglehorn Long Bow
	[13037] = {base_speed = 2.8},    -- Crystalpine Stinger
	[13038] = {base_speed = 2},    -- Swiftwind
	[13039] = {base_speed = 2.6},    -- Skull Splitting Crossbow
	[13040] = {base_speed = 3.1},    -- Heartseeking Crossbow
	[13062] = {base_speed = 1.9},    -- Thunderwood
	[13063] = {base_speed = 1.4},    -- Starfaller
	[13064] = {base_speed = 1.6},    -- Jaina's Firestarter
	[13065] = {base_speed = 1.9},    -- Wand of Allistarj
	[13136] = {base_speed = 2.6},    -- Lil Timmy's Peashooter
	[13137] = {base_speed = 2.6},    -- Ironweaver
	[13138] = {base_speed = 2.8},    -- The Silencer
	[13139] = {base_speed = 2.7},    -- Guttbuster
	[13146] = {base_speed = 2.3},    -- Shell Launcher Shotgun
	[13147] = {base_speed = 2},    -- Monster - Bow, White
	[13175] = {base_speed = 1.6},    -- Voone's Twitchbow
	[13248] = {base_speed = 2.6},    -- Burstshot Harquebus
	[13290] = {base_speed = 2},    -- Monster - Wand, Horde Purple Orb
	[13291] = {base_speed = 2},    -- Monster - Wand, Horde Red Feathered
	[13292] = {base_speed = 2},    -- Monster - Wand, Horde Demon Skull
	[13293] = {base_speed = 2},    -- Monster - Wand, Horde Dark Skull
	[13380] = {base_speed = 2.9},    -- Willey's Portable Howitzer
	[13396] = {base_speed = 1.8},    -- Skul's Ghastly Touch
	[13474] = {base_speed = 1.9},    -- Farmer Dalson's Shotgun
	[13534] = {base_speed = 1.9},    -- Banshee Finger
	[13824] = {base_speed = 2.5},    -- Recurve Long Bow
	[13825] = {base_speed = 1.8},    -- Primed Musket
	[13923] = {base_speed = 2},    -- Monster - Gun, Tauren Blade Silver
	[13924] = {base_speed = 2},    -- Monster - Gun, Tauren Scope Blade Feathered Silver Deluxe
	[13938] = {base_speed = 1.9},    -- Bonecreeper Stylus
	[14105] = {base_speed = 2},    -- Monster - Bow, C01/B02 White
	[14118] = {base_speed = 2},    -- Monster - Bow, C02/B02 Black
	[14394] = {base_speed = 1.8},    -- Durability Bow
	[14642] = {base_speed = 2},    -- Monster - Gun, Tauren Feathers Silver
	[15204] = {base_speed = 1.8},    -- Moonstone Wand
	[15205] = {base_speed = 2.6},    -- Owlsight Rifle
	[15279] = {base_speed = 1.4},    -- Ivory Wand
	[15280] = {base_speed = 1.8},    -- Wizard's Hand
	[15281] = {base_speed = 1.5},    -- Glowstar Rod
	[15282] = {base_speed = 1.4},    -- Dragon Finger
	[15283] = {base_speed = 1.7},    -- Lunar Wand
	[15284] = {base_speed = 2.2},    -- Long Battle Bow
	[15285] = {base_speed = 2.6},    -- Archer's Longbow
	[15286] = {base_speed = 2.8},    -- Long Redwood Bow
	[15287] = {base_speed = 2.2},    -- Crusader Bow
	[15288] = {base_speed = 2.6},    -- Blasthorn Bow
	[15289] = {base_speed = 2.3},    -- Archstrike Bow
	[15291] = {base_speed = 2.7},    -- Harpy Needler
	[15294] = {base_speed = 2.8},    -- Siege Bow
	[15295] = {base_speed = 2.3},    -- Quillfire Bow
	[15296] = {base_speed = 1.7},    -- Hawkeye Bow
	[15322] = {base_speed = 2.5},    -- Smoothbore Gun
	[15323] = {base_speed = 2.3},    -- Percussion Shotgun
	[15324] = {base_speed = 2.5},    -- Burnside Rifle
	[15325] = {base_speed = 2.2},    -- Sharpshooter Harquebus
	[15460] = {base_speed = 2},    -- Monster - Gun, Shotgun
	[15465] = {base_speed = 1.8},    -- Stingshot Wand
	[15691] = {base_speed = 2.9},    -- Sidegunner Shottie
	[15692] = {base_speed = 1.9},    -- Kodo Brander
	[15807] = {base_speed = 2.5},    -- Light Crossbow
	[15808] = {base_speed = 2.7},    -- Fine Light Crossbow
	[15809] = {base_speed = 2.8},    -- Heavy Crossbow
	[15995] = {base_speed = 2.5},    -- Thorium Rifle
	[16004] = {base_speed = 2.7},    -- Dark Iron Rifle
	[16007] = {base_speed = 3},    -- Flawless Arcanite Rifle
	[16582] = {base_speed = 2},    -- Monster - Wand, Horde Green Feathered
	[16622] = {base_speed = 2.8},    -- Thornflinger
	[16789] = {base_speed = 1.5},    -- Captain Rackmore's Tiller
	[16992] = {base_speed = 2.7},    -- Smokey's Explosive Launcher
	[16993] = {base_speed = 1.9},    -- Smokey's Fireshooter
	[16996] = {base_speed = 2.5},    -- Gorewood Bow
	[16997] = {base_speed = 1.3},    -- Stormrager
	[17042] = {base_speed = 1.9},    -- Nail Spitter
	[17069] = {base_speed = 2.5},    -- Striker's Mark
	[17072] = {base_speed = 2.6},    -- Blastershot Launcher
	[17077] = {base_speed = 2},    -- Crimson Shocker
	[17686] = {base_speed = 2.9},    -- Master Hunter's Bow
	[17687] = {base_speed = 2.9},    -- Master Hunter's Rifle
	[17717] = {base_speed = 1.7},    -- Megashot Rifle
	[17745] = {base_speed = 1.6},    -- Noxious Shooter
	[17753] = {base_speed = 2.8},    -- Verdant Keeper's Aim
	[18282] = {base_speed = 2.5},    -- Core Marksman Rifle
	[18301] = {base_speed = 1.7},    -- Lethtendris's Wand
	[18323] = {base_speed = 2.4},    -- Satyr's Bow
	[18338] = {base_speed = 1.6},    -- Wand of Arcane Potency
	[18388] = {base_speed = 2.9},    -- Stoneshatter
	[18460] = {base_speed = 2.5},    -- Unsophisticated Hand Cannon
	[18482] = {base_speed = 2.2},    -- Ogre Toothpick Shooter
	[18483] = {base_speed = 1.6},    -- Mana Channeling Wand
	[18680] = {base_speed = 2.8},    -- Ancient Bone Bow
	[18713] = {base_speed = 2.9},    -- Rhok'delar, Longbow of the Ancient Keepers
	[18729] = {base_speed = 2.3},    -- Screeching Bow
	[18738] = {base_speed = 3.3},    -- Carapace Spine Crossbow
	[18755] = {base_speed = 2.6},    -- Xorothian Firestick
	[18761] = {base_speed = 1.8},    -- Oblivion's Touch
	[18763] = {base_speed = 2.5},    -- TEST GUN Alliance20 
	[18764] = {base_speed = 2.5},    -- TEST GUN Raid
	[18765] = {base_speed = 2.5},    -- TEST GUN Horde50
	[18833] = {base_speed = 1.8},    -- Grand Marshal's Bullseye
	[18835] = {base_speed = 1.8},    -- High Warlord's Recurve
	[18836] = {base_speed = 2.9},    -- Grand Marshal's Repeater
	[18837] = {base_speed = 2.9},    -- High Warlord's Crossbow
	[18855] = {base_speed = 2.9},    -- Grand Marshal's Hand Cannon
	[18860] = {base_speed = 2.9},    -- High Warlord's Street Sweeper
	[19107] = {base_speed = 3.3},    -- Bloodseeker
	[19108] = {base_speed = 1.5},    -- Wand of Biting Cold
	[19114] = {base_speed = 2.5},    -- Highland Bow
	[19118] = {base_speed = 1.4},    -- Nature's Breath
	[19130] = {base_speed = 1.7},    -- Cold Snap
	[19226] = {base_speed = 0.5},    -- Fast Test Fist
	[19350] = {base_speed = 2.6},    -- Heartstriker
	[19361] = {base_speed = 3.4},    -- Ashjre'thul, Crossbow of Smiting
	[19367] = {base_speed = 1.6},    -- Dragon's Touch
	[19368] = {base_speed = 2.8},    -- Dragonbreath Hand Cannon
	[19435] = {base_speed = 1.4},    -- Essence Gatherer
	[19489] = {base_speed = 3.3},    -- 3300 Test Crossbow 63 blue
	[19490] = {base_speed = 2.8},    -- 2800 Test Bow 63 Blue
	[19558] = {base_speed = 2.4},    -- Outrider's Bow
	[19559] = {base_speed = 2.4},    -- Outrider's Bow
	[19560] = {base_speed = 2.4},    -- Outrider's Bow
	[19561] = {base_speed = 2.4},    -- Outrider's Bow
	[19562] = {base_speed = 2.4},    -- Outrunner's Bow
	[19563] = {base_speed = 2.4},    -- Outrunner's Bow
	[19564] = {base_speed = 2.4},    -- Outrunner's Bow
	[19565] = {base_speed = 2.4},    -- Outrunner's Bow
	[19837] = {base_speed = 2.5},    -- Test Ranged Slot
	[19853] = {base_speed = 2.8},    -- Gurubashi Dwarf Destroyer
	[19861] = {base_speed = 1.5},    -- Touch of Chaos
	[19868] = {base_speed = 3},    -- Mandokir's Sting DEPRECATED
	[19927] = {base_speed = 1.7},    -- Mar'li's Touch
	[19966] = {base_speed = 2.8},    -- Thrice Strung Longbow DEPRECATED
	[19967] = {base_speed = 1.8},    -- Thoughtblighter
	[19983] = {base_speed = 2},    -- Monster - Wand, Horde Demon Skull Red
	[19993] = {base_speed = 2.8},    -- Hoodoo Hunting Bow
	[20038] = {base_speed = 2.6},    -- Mandokir's Sting
	[20082] = {base_speed = 1.9},    -- Woestave
	[20146] = {base_speed = 2.5},    -- 90 Epic Warrior Gun
	[20245] = {base_speed = 2.5},    -- 90 Green Warrior Gun
	[20278] = {base_speed = 2.5},    -- 90 Epic Rogue Bow
	[20285] = {base_speed = 2.5},    -- 63 Green Warrior Gun
	[20299] = {base_speed = 2.5},    -- 90 Green Rogue Bow
	[20313] = {base_speed = 2.5},    -- 63 Green Rogue Bow
	[20335] = {base_speed = 1.3},    -- 90 Epic Frost Wand
	[20350] = {base_speed = 1.3},    -- 90 Green Frost Wand
	[20363] = {base_speed = 1.3},    -- 63 Green Frost Wand
	[20368] = {base_speed = 1.5},    -- Bland Bow of Steadiness
	[20437] = {base_speed = 2.4},    -- Outrider's Bow
	[20438] = {base_speed = 2.4},    -- Outrunner's Bow
	[20488] = {base_speed = 2.9},    -- Rhok'delar, Longbow of the Ancient Keepers DEP
	[20599] = {base_speed = 3.1},    -- Polished Ironwood Crossbow
	[20646] = {base_speed = 2.6},    -- Sandstrider's Mark
	[20663] = {base_speed = 2.7},    -- Deep Strike Bow
	[20672] = {base_speed = 1.5},    -- Sparkling Crystal Wand
	[20722] = {base_speed = 2.8},    -- Crystal Slugthrower
	[20838] = {base_speed = 2.3},    -- Sunstrider Bow
	[20910] = {base_speed = 2},    -- Stiff Shortbow
	[20980] = {base_speed = 2.3},    -- Warder's Shortbow
	[21036] = {base_speed = 2.8},    -- 2800 test bow
	[21057] = {base_speed = 1.3},    -- 63 Blue Fire Wand
	[21070] = {base_speed = 1.3},    -- 66 Epic Fire Wand
	[21085] = {base_speed = 1.3},    -- 63 Blue Shadow Wand
	[21098] = {base_speed = 1.3},    -- 66 Epic Shadow Wand
	[21124] = {base_speed = 1.4},    -- Ahn'Qiraj Wand [PH]
	[21272] = {base_speed = 2.6},    -- Blessed Qiraji Musket
	[21459] = {base_speed = 3.1},    -- Crossbow of Imminent Doom
	[21478] = {base_speed = 2.2},    -- Bow of Taut Sinew
	[21550] = {base_speed = 2},    -- Monster - Crossbow, Hakkari
	[21554] = {base_speed = 2},    -- Monster - Gun, PvP Horde
	[21564] = {base_speed = 2},    -- Monster - Gun, Kaldorei PVP Alliance
	[21603] = {base_speed = 1.6},    -- Wand of Qiraji Nobility
	[21616] = {base_speed = 2.7},    -- Huhuran's Stinger
	[21800] = {base_speed = 2.8},    -- Silithid Husked Launcher
	[21801] = {base_speed = 1.6},    -- Antenna of Invigoration
	[22254] = {base_speed = 1.5},    -- Wand of Eternal Light
	[22318] = {base_speed = 2.9},    -- Malgen's Long Bow
	[22347] = {base_speed = 3.2},    -- Fahrad's Reloading Repeater
	[22408] = {base_speed = 1.3},    -- Ritssyn's Wand of Bad 
	[22646] = {base_speed = 3.0},	-- Master Spellstone (relic)
	[22656] = {base_speed = 3},    -- The Purifier
	[22810] = {base_speed = 2},    -- Toxin Injector
	[22811] = {base_speed = 2.9},    -- Soulstring
	[22812] = {base_speed = 3.2},    -- Nerubian Slavemaker
	[22820] = {base_speed = 1.5},    -- Wand of Fates
	[22821] = {base_speed = 1.5},    -- Doomfinger
	[22969] = {base_speed = 2},    -- Ven'jashi's Bow
	[22971] = {base_speed = 1.6},    -- Hoodoo Wand
	[22982] = {base_speed = 1.7},    -- Farstrider's Longbow
	[22997] = {base_speed = 1.4},    -- Ley-Keeper's Wand
	[23009] = {base_speed = 1.5},    -- Wand of the Whispering Dead
	[23051] = {base_speed = 2},    -- Monster - Bow, Raid Snake ZG
	[23052] = {base_speed = 2},    -- Monster - Crossbow, Ornate
	[23177] = {base_speed = 1.3},    -- Lady Falther'ess' Finger
	[23347] = {base_speed = 2.5},    -- Weathered Crossbow
	[23398] = {base_speed = 2.1},    -- Worn Ranger's Bow
	[23409] = {base_speed = 2.7},    -- Well Crafted Long Bow
	[23557] = {base_speed = 3},    -- Larvae of the Great Worm
	[23742] = {base_speed = 2.8},    -- Fel Iron Musket
	[23746] = {base_speed = 3},    -- Adamantite Rifle
	[23747] = {base_speed = 2.4},    -- Felsteel Boomstick
	[23748] = {base_speed = 3.1},    -- Ornate Khorium Rifle
	[23889] = {base_speed = 2},    -- Monster - Bow, Horde PVP
	[24136] = {base_speed = 2.8},    -- Farstrider's Bow
	[24138] = {base_speed = 3.1},    -- Silver Crossbow
	[24244] = {base_speed = 2},    -- Monster - Gun, Draenei A01 Orange
	[24319] = {base_speed = 2},    -- Monster - Bow, Blood Elf B01 Blue
	[24326] = {base_speed = 2},    -- Monster - Bow, Blood Elf B01 Yellow
	[24342] = {base_speed = 1.6},    -- Stillpine Shocker
	[24353] = {base_speed = 2.7},    -- Crossbow of the Hand
	[24380] = {base_speed = 1.6},    -- Calming Spore Reed
	[24381] = {base_speed = 2.9},    -- Coilfang Needler
	[24389] = {base_speed = 3},    -- Legion Blunderbuss
	[24433] = {base_speed = 2.5},    -- Crossbow of the Albatross
	[24441] = {base_speed = 2.5},    -- Exodar Crossbow
	[24530] = {base_speed = 2.5},    -- 130 Epic Warrior Gun
	[24569] = {base_speed = 1.3},    -- 130 Test Caster Wand
	[25240] = {base_speed = 2.7},    -- Azerothian Longbow
	[25241] = {base_speed = 2.7},    -- Ashenvale Longbow
	[25242] = {base_speed = 2.7},    -- Telaari Longbow
	[25243] = {base_speed = 2.7},    -- Windtalker Bow
	[25244] = {base_speed = 2.7},    -- Viper Bow
	[25245] = {base_speed = 2.7},    -- Razorsong Bow
	[25246] = {base_speed = 2.7},    -- Thalassian Compound Bow
	[25247] = {base_speed = 2.7},    -- Expert's Bow
	[25248] = {base_speed = 2.7},    -- Talbuk Hunting Bow
	[25249] = {base_speed = 2.7},    -- Ranger's Recurved Bow
	[25250] = {base_speed = 2.7},    -- Rocslayer Longbow
	[25251] = {base_speed = 2.7},    -- Orc Flatbow
	[25252] = {base_speed = 2.7},    -- Dream Catcher Bow
	[25253] = {base_speed = 2.7},    -- Windspear Longbow
	[25254] = {base_speed = 2.7},    -- Tower Crossbow
	[25255] = {base_speed = 2.7},    -- Ram's Head Crossbow
	[25256] = {base_speed = 2.7},    -- Stronghold Crossbow
	[25257] = {base_speed = 2.7},    -- Citadel Crossbow
	[25258] = {base_speed = 2.7},    -- Repeater Crossbow
	[25259] = {base_speed = 2.7},    -- Collapsible Crossbow
	[25260] = {base_speed = 2.7},    -- Archer's Crossbow
	[25261] = {base_speed = 2.7},    -- Mighty Crossbow
	[25262] = {base_speed = 2.7},    -- Battle Damaged Crossbow
	[25263] = {base_speed = 2.7},    -- Assassins' Silent Crossbow
	[25264] = {base_speed = 2.7},    -- Pocket Ballista
	[25265] = {base_speed = 2.7},    -- Barreled Crossbow
	[25266] = {base_speed = 2.7},    -- Well-Balanced Crossbow
	[25267] = {base_speed = 2.7},    -- Rampant Crossbow
	[25268] = {base_speed = 2.7},    -- Lead-Slug Shotgun
	[25269] = {base_speed = 2.7},    -- Longbeard Rifle
	[25270] = {base_speed = 2.7},    -- Gnomish Assault Rifle
	[25271] = {base_speed = 2.7},    -- Croc-Hunter's Rifle
	[25272] = {base_speed = 2.7},    -- PC-54 Shotgun
	[25273] = {base_speed = 2.7},    -- Sawed-Off Shotgun
	[25274] = {base_speed = 2.7},    -- Cliffjumper Shotgun
	[25275] = {base_speed = 2.7},    -- Dragonbreath Musket
	[25276] = {base_speed = 2.7},    -- Tauren Runed Musket
	[25277] = {base_speed = 2.7},    -- Sporting Rifle
	[25278] = {base_speed = 2.7},    -- Nessingwary Longrifle
	[25279] = {base_speed = 2.7},    -- Sen'jin Longrifle
	[25280] = {base_speed = 2.7},    -- Game Hunter Musket
	[25281] = {base_speed = 2.7},    -- Big-Boar Battle Rifle
	[25282] = {base_speed = 1.7},    -- Mahogany Wand
	[25283] = {base_speed = 1.7},    -- Crystallized Ebony Wand
	[25284] = {base_speed = 1.7},    -- Purpleheart Wand
	[25285] = {base_speed = 1.7},    -- Bloodwood Wand
	[25286] = {base_speed = 1.7},    -- Yew Wand
	[25287] = {base_speed = 1.7},    -- Magician's Wand
	[25288] = {base_speed = 1.7},    -- Conjurer's Wand
	[25289] = {base_speed = 1.7},    -- Majestic Wand
	[25290] = {base_speed = 1.7},    -- Solitaire Wand
	[25291] = {base_speed = 1.7},    -- Nobility Torch
	[25292] = {base_speed = 1.7},    -- Mechano-Wand
	[25293] = {base_speed = 1.7},    -- Draenethyst Wand
	[25294] = {base_speed = 1.7},    -- Dragonscale Wand
	[25295] = {base_speed = 1.7},    -- Flawless Wand
	[25405] = {base_speed = 1.8},    -- Rusted Musket
	[25406] = {base_speed = 2.5},    -- Broken Longbow
	[25496] = {base_speed = 2.8},    -- Mag'har Bow
	[25544] = {base_speed = 2.7},    -- Zerid's Vintage Musket
	[25629] = {base_speed = 1.7},    -- Ogre Handler's Shooter
	[25632] = {base_speed = 1.7},    -- Wand of Happiness
	[25639] = {base_speed = 2.5},    -- Hemet's Elekk Gun
	[25640] = {base_speed = 1.8},    -- Nesingwary Safari Stick
	[25806] = {base_speed = 1.8},    -- Nethekurse's Rod of Torment
	[25808] = {base_speed = 1.8},    -- Rod of Dire Shadows
	[25861] = {base_speed = 1.8},    -- Crude Throwing Axe
	[25871] = {base_speed = 2},    -- Standard Thrown Weapon
	[25872] = {base_speed = 1.7},    -- Balanced Throwing Dagger
	[25873] = {base_speed = 1.9},    -- Keen Throwing Knife
	[25874] = {base_speed = 3},    -- Large Throwing Knife
	[25875] = {base_speed = 2},    -- Deadly Throwing Axe
	[25876] = {base_speed = 1.8},    -- Gleaming Throwing Axe
	[25877] = {base_speed = 2.2},    -- Master's Throwing Dagger
	[25878] = {base_speed = 1.8},    -- Dusksteel Throwing Knife
	[25939] = {base_speed = 1.9},    -- Voidfire Wand
	[25953] = {base_speed = 2.7},    -- Ethereal Warp-Bow
	[25971] = {base_speed = 3.3},    -- Stout Oak Longbow
	[25972] = {base_speed = 2.5},    -- Deadeye's Piece
	[25973] = {base_speed = 1.7},    -- Dark Augur's Wand
	[26714] = {base_speed = 2.7},    -- 59 TEST Green Bow
	[26715] = {base_speed = 2.7},    -- 60 TEST Green Bow
	[26716] = {base_speed = 2.7},    -- 61 TEST Green Bow
	[26717] = {base_speed = 2.7},    -- 62 TEST Green Bow
	[26718] = {base_speed = 2.7},    -- 63 TEST Green Bow
	[26719] = {base_speed = 2.7},    -- 64 TEST Green Bow
	[26720] = {base_speed = 2.7},    -- 65 TEST Green Bow
	[26721] = {base_speed = 2.7},    -- 66 TEST Green Bow
	[26722] = {base_speed = 2.7},    -- 67 TEST Green Bow
	[26723] = {base_speed = 2.7},    -- 68 TEST Green Bow
	[26724] = {base_speed = 2.7},    -- 69 TEST Green Bow
	[26725] = {base_speed = 2.7},    -- 70 TEST Green Bow
	[26726] = {base_speed = 2.7},    -- 71 TEST Green Bow
	[26727] = {base_speed = 2.7},    -- 72 TEST Green Bow
	[26728] = {base_speed = 2.7},    -- 59 TEST Green Crossbow
	[26729] = {base_speed = 2.7},    -- 60 TEST Green Crossbow
	[26730] = {base_speed = 2.7},    -- 61 TEST Green Crossbow
	[26731] = {base_speed = 2.7},    -- 62 TEST Green Crossbow
	[26732] = {base_speed = 2.7},    -- 63 TEST Green Crossbow
	[26733] = {base_speed = 2.7},    -- 64 TEST Green Crossbow
	[26734] = {base_speed = 2.7},    -- 65 TEST Green Crossbow
	[26735] = {base_speed = 2.7},    -- 66 TEST Green Crossbow
	[26736] = {base_speed = 2.7},    -- 67 TEST Green Crossbow
	[26737] = {base_speed = 2.7},    -- 68 TEST Green Crossbow
	[26738] = {base_speed = 2.7},    -- 69 TEST Green Crossbow
	[26739] = {base_speed = 2.7},    -- 70 TEST Green Crossbow
	[26740] = {base_speed = 2.7},    -- 71 TEST Green Crossbow
	[26741] = {base_speed = 2.7},    -- 72 TEST Green Crossbow
	[26742] = {base_speed = 2.7},    -- 59 TEST Green Gun
	[26743] = {base_speed = 2.7},    -- 60 TEST Green Gun
	[26744] = {base_speed = 2.7},    -- 61 TEST Green Gun
	[26745] = {base_speed = 2.7},    -- 62 TEST Green Gun
	[26746] = {base_speed = 2.7},    -- 63 TEST Green Gun
	[26747] = {base_speed = 2.7},    -- 64 TEST Green Gun
	[26748] = {base_speed = 2.7},    -- 65 TEST Green Gun
	[26749] = {base_speed = 2.7},    -- 66 TEST Green Gun
	[26750] = {base_speed = 2.7},    -- 67 TEST Green Gun
	[26751] = {base_speed = 2.7},    -- 68 TEST Green Gun
	[26752] = {base_speed = 2.7},    -- 69 TEST Green Gun
	[26753] = {base_speed = 2.7},    -- 70 TEST Green Gun
	[26754] = {base_speed = 2.7},    -- 71 TEST Green Gun
	[26755] = {base_speed = 2.7},    -- 72 TEST Green Gun
	[26756] = {base_speed = 1.7},    -- 59 TEST Green Wand
	[26757] = {base_speed = 1.7},    -- 60 TEST Green Wand
	[26758] = {base_speed = 1.7},    -- 61 TEST Green Wand
	[26759] = {base_speed = 1.7},    -- 62 TEST Green Wand
	[26760] = {base_speed = 1.7},    -- 63 TEST Green Wand
	[26761] = {base_speed = 1.7},    -- 64 TEST Green Wand
	[26762] = {base_speed = 1.7},    -- 65 TEST Green Wand
	[26763] = {base_speed = 1.7},    -- 66 TEST Green Wand
	[26764] = {base_speed = 1.7},    -- 67 TEST Green Wand
	[26765] = {base_speed = 1.7},    -- 68 TEST Green Wand
	[26766] = {base_speed = 1.7},    -- 69 TEST Green Wand
	[26767] = {base_speed = 1.7},    -- 70 TEST Green Wand
	[26768] = {base_speed = 1.7},    -- 71 TEST Green Wand
	[26769] = {base_speed = 1.7},    -- 72 TEST Green Wand
	[27401] = {base_speed = 2.8},    -- Arugoo's Crossbow of Destruction
	[27402] = {base_speed = 2.8},    -- Huntsman's Crossbow
	[27403] = {base_speed = 1.4},    -- Stillpine Stinger
	[27404] = {base_speed = 1.8},    -- Lightspark
	[27507] = {base_speed = 3},    -- Adamantine Repeater
	[27526] = {base_speed = 2.4},    -- Skyfire Hawk-Bow
	[27540] = {base_speed = 1.8},    -- Nexus Torch
	[27631] = {base_speed = 1.4},    -- Needle Shrike
	[27640] = {base_speed = 2.8},    -- Hand of Argus Crossfire
	[27794] = {base_speed = 2.9},    -- Recoilless Rocket Ripper X-54
	[27817] = {base_speed = 2.8},    -- Starbolt Longbow
	[27885] = {base_speed = 1.8},    -- Soul-Wand of the Aldor
	[27890] = {base_speed = 1.8},    -- Wand of the Netherwing
	[27898] = {base_speed = 2},    -- Wrathfire Hand-Cannon
	[27916] = {base_speed = 1.6},    -- Sethekk Feather-Darts
	[27928] = {base_speed = 1.6},    -- Terminal Edge
	[27929] = {base_speed = 1.6},    -- Terminal Edge
	[27930] = {base_speed = 2.5},    -- Splintermark
	[27931] = {base_speed = 2.5},    -- Splintermark
	[27939] = {base_speed = 1.9},    -- Incendic Rod
	[27942] = {base_speed = 1.9},    -- Incendic Rod
	[27987] = {base_speed = 3},    -- Melmorta's Twilight Longbow
	[28023] = {base_speed = 2},    -- Monster - Throwing Axe (Poison)
	[28062] = {base_speed = 2.9},    -- Expedition Repeater
	[28063] = {base_speed = 1.3},    -- Survivalist's Wand
	[28151] = {base_speed = 1.6},    -- Arcanist's Wand
	[28152] = {base_speed = 2.7},    -- Quel'Thalas Recurve
	[28165] = {base_speed = 2.5},    -- TEST GUN RocketLauncher
	[28258] = {base_speed = 1.6},    -- Nethershrike
	[28286] = {base_speed = 3},    -- Telescopic Sharprifle
	[28294] = {base_speed = 3.1},    -- Gladiator's Heavy Crossbow
	[28319] = {base_speed = 1.9},    -- Gladiator's War Edge
	[28320] = {base_speed = 1.9},    -- Gladiator's Touch of Defeat
	[28386] = {base_speed = 1.8},    -- Nether Core's Control Rod
	[28397] = {base_speed = 3},    -- Emberhawk Crossbow
	[28408] = {base_speed = 2.3},    -- Broken Silver Star
	[28504] = {base_speed = 2.8},    -- Steelhawk Crossbow
	[28531] = {base_speed = 1.7},    -- Barbed Shrike
	[28532] = {base_speed = 1.7},    -- Silver Throwing Knifes
	[28533] = {base_speed = 1.7},    -- Wooden Boomerang
	[28534] = {base_speed = 1.7},    -- Fel Tipped Dart
	[28535] = {base_speed = 1.7},    -- Amani Throwing Axe
	[28536] = {base_speed = 1.7},    -- Jagged Guillotine
	[28537] = {base_speed = 1.7},    -- Wildhammer Throwing Axe
	[28538] = {base_speed = 1.7},    -- Forked Shuriken
	[28539] = {base_speed = 1.7},    -- Razor-Edged Boomerang
	[28540] = {base_speed = 1.7},    -- Arakkoa Talon-Axe
	[28541] = {base_speed = 1.7},    -- Sawshrike
	[28542] = {base_speed = 1.7},    -- Heartseeker Knives
	[28543] = {base_speed = 1.7},    -- Dreghood Throwing Axe
	[28544] = {base_speed = 1.7},    -- Assassin's Shuriken
	[28581] = {base_speed = 2.7},    -- Wolfslayer Sniper Rifle
	[28588] = {base_speed = 1.5},    -- Blue Diamond Witchwand
	[28659] = {base_speed = 1.4},    -- Xavian Stiletto
	[28673] = {base_speed = 1.5},    -- Tirisfal Wand of Ascendancy
	[28772] = {base_speed = 2.9},    -- Sunfury Bow of the Phoenix
	[28783] = {base_speed = 1.5},    -- Eredar Wand of Obliteration
	[28826] = {base_speed = 1.2},    -- Shuriken of Negation
	[28933] = {base_speed = 3.2},    -- High Warlord's Heavy Crossbow
	[28960] = {base_speed = 3.2},    -- Grand Marshal's Heavy Crossbow
	[28972] = {base_speed = 2.2},    -- Flightblade Throwing Axe
	[28979] = {base_speed = 1.6},    -- Light Throwing Knife
	[29007] = {base_speed = 1.9},    -- Weighted Throwing Axe
	[29008] = {base_speed = 1.9},    -- Sharp Throwing Axe
	[29009] = {base_speed = 1.8},    -- Heavy Throwing Dagger
	[29010] = {base_speed = 1.8},    -- Wicked Throwing Dagger
	[29013] = {base_speed = 1.8},    -- Jagged Throwing Axe
	[29014] = {base_speed = 1.8},    -- Blacksteel Throwing Dagger
	[29115] = {base_speed = 2.4},    -- Consortium Blaster
	[29149] = {base_speed = 1.3},    -- Sporeling's Firestick
	[29151] = {base_speed = 2.7},    -- Veteran's Musket
	[29152] = {base_speed = 2.8},    -- Marksman's Bow
	[29200] = {base_speed = 2.8},    -- Falfindel's Blaster
	[29201] = {base_speed = 2.2},    -- Thick Bronze Darts
	[29202] = {base_speed = 2.2},    -- Whirling Steel Axes
	[29203] = {base_speed = 2.2},    -- Enchanted Thorium Blades
	[29204] = {base_speed = 2.2},    -- Felsteel Whisper Knives
	[29210] = {base_speed = 3},    -- Assassin's Throwing Axe
	[29211] = {base_speed = 2.2},    -- Fitz's Throwing Axe
	[29212] = {base_speed = 1.8},    -- Balanced Stone Dirk
	[29350] = {base_speed = 1.5},    -- The Black Stalk
	[29351] = {base_speed = 3},    -- Wrathtide Longbow
	[29378] = {base_speed = 1.9},    -- Starheart Baton
	[29584] = {base_speed = 1.8},    -- Throat Piercers
	[29626] = {base_speed = 2},    -- Monster - Gun, Draenei A01
	[29627] = {base_speed = 2},    -- Monster - Gun, Draenei A01 Gold
	[29628] = {base_speed = 2},    -- Monster - Gun, Draenei A01 Olive
	[29629] = {base_speed = 2},    -- Monster - Gun, Draenei A01 Purple
	[29779] = {base_speed = 1.4},    -- Rejuvenating Scepter
	[29884] = {base_speed = 2.7},    -- Hunter 105 Epic Test Gun
	[29888] = {base_speed = 2.7},    -- Hunter 150 Epic Test Gun
	[29915] = {base_speed = 1.6},    -- Desolation Rod
	[29916] = {base_speed = 2.2},    -- Ironstar Repeater
	[29949] = {base_speed = 2.9},    -- Arcanite Steam-Pistol
	[29982] = {base_speed = 1.5},    -- Wand of the Forgotten Star
	[30025] = {base_speed = 1.4},    -- Serpentshrine Shuriken
	[30080] = {base_speed = 1.5},    -- Luminescent Rod of the Naaru
	[30105] = {base_speed = 3},    -- Serpent Spine Longbow
	[30128] = {base_speed = 2.5},    -- Monster - Gun, Techno
	[30226] = {base_speed = 2.5},    -- Alley's Recurve
	[30227] = {base_speed = 1.7},    -- Mark V's Throwing Star
	[30252] = {base_speed = 1.7},    -- Unearthed Enkaat Wand
	[30279] = {base_speed = 2.2},    -- Mama's Insurance
	[30318] = {base_speed = 2.9},    -- Netherstrand Longbow
	[30390] = {base_speed = 2.9},    -- Monster - Bow, Netherstrand Longbow
	[30397] = {base_speed = 2.7},    -- Spymaster's Crossbow
	[30452] = {base_speed = 2},    -- Monster - Bow, Spirit Hunter
	[30456] = {base_speed = 2},    -- Monster - Bow, Hunter Epic
	[30523] = {base_speed = 1.7},    -- Hotshot Cattle Prod
	[30568] = {base_speed = 1.4},    -- The Sharp Cookie
	[30580] = {base_speed = 2},    -- Monster - Crossbow, Draenei A01 Silver
	[30599] = {base_speed = 1.4},    -- Avenging Blades
	[30724] = {base_speed = 2.6},    -- Barrel-Blade Longrifle
	[30757] = {base_speed = 2.3},    -- Draenic Light Crossbow
	[30758] = {base_speed = 2.2},    -- Aldor Guardian Rifle
	[30759] = {base_speed = 2.1},    -- Mag'hari Light Recurve
	[30859] = {base_speed = 1.3},    -- Wand of the Seer
	[30906] = {base_speed = 3},    -- Bristleblitz Striker
	[31000] = {base_speed = 2.6},    -- Bloodwarder's Rifle
	[31072] = {base_speed = 2.6},    -- Lohn'goron, Bow of the Torn-heart
	[31083] = {base_speed = 2.9},    -- Monster - Bow, Val'zareq's
	[31204] = {base_speed = 2.8},    -- The Gunblade
	[31270] = {base_speed = 1.4},    -- Banshee Rod
	[31303] = {base_speed = 2.8},    -- Valanos' Longbow
	[31323] = {base_speed = 2.7},    -- Don Santos' Famous Hunting Rifle
	[31325] = {base_speed = 2},    -- Monster - Bow, Lady Vashj
	[31348] = {base_speed = 2},    -- Monster - Bow, Mordenai
	[31352] = {base_speed = 2},    -- Monster - Crossbow, Green Snake
	[31416] = {base_speed = 2.2},    -- Scorch Wood Bow
	[31424] = {base_speed = 1.6},    -- Arcane Wand of Sylvanaar
	[31474] = {base_speed = 1.6},    -- Wand of the Ancestors
	[31497] = {base_speed = 1},    -- Monster - Throwing Trident, Wicked
	[31499] = {base_speed = 1},    -- Monster - Throwing Trident, Wicked Blue Glow
	[31724] = {base_speed = 1.6},    -- Arakkoa Divining Rod
	[31761] = {base_speed = 1.7},    -- Talonbranch Wand
	[31762] = {base_speed = 2.7},    -- Feather-Wrapped Bow
	[31986] = {base_speed = 3},    -- Merciless Gladiator's Crossbow of the Phoenix
	[32054] = {base_speed = 1.3},    -- Merciless Gladiator's War Edge
	[32187] = {base_speed = 3.2},    -- Chancellor's Heavy Crossbow
	[32253] = {base_speed = 2.9},    -- Legionkiller
	[32325] = {base_speed = 1.9},    -- Rifle of the Stoic Guardian
	[32326] = {base_speed = 1.4},    -- Twisted Blades of Zarak
	[32336] = {base_speed = 3},    -- Black Bow of the Betrayer
	[32343] = {base_speed = 1.5},    -- Wand of Prismatic Focus
	[32363] = {base_speed = 1.5},    -- Naaru-Blessed Life Rod
	[32378] = {base_speed = 2.3},    -- Silver Star
	[32482] = {base_speed = 1.9},    -- Touch of Victory
	[32613] = {base_speed = 3.3},    -- Monster - Black Temple - Bow, 2H - Shadowmoon Houndmaster
	[32645] = {base_speed = 2.8},    -- Crystalline Crossbow
	[32650] = {base_speed = 1.5},    -- Cerulean Crystal Rod
	[32730] = {base_speed = 2},    -- Monster - Bow, Outland Raid D04
	[32740] = {base_speed = 1.5},    -- Monster - Dagger (Maiev)
	[32756] = {base_speed = 2.8},    -- Gyro-Balanced Khorium Destroyer
	[32780] = {base_speed = 2},    -- The Boomstick
	[32826] = {base_speed = 2},    -- Monster - Bow, Scryer (Uber)
	[32827] = {base_speed = 2},    -- Monster - Bow, Scryer (Hobb)
	[32831] = {base_speed = 1.8},    -- Jeweled Rod
	[32832] = {base_speed = 2.2},    -- Scout's Throwing Knives
	[32872] = {base_speed = 1.4},    -- Illidari Rod of Discipline
	[32876] = {base_speed = 2},    -- Monster - Black Temple - Crossbow - Dragonmaw Sky Stalker
	[32962] = {base_speed = 1.9},    -- Merciless Gladiator's Touch of Defeat
	[33006] = {base_speed = 3},    -- Vengeful Gladiator's Heavy Crossbow
	[33192] = {base_speed = 1.5},    -- Carved Witch Doctor's Stick
	[33273] = {base_speed = 2.7},    -- Seasoned Marshwood Bow
	[33274] = {base_speed = 2.7},    -- Mercenary's Crossbow
	[33338] = {base_speed = 2},    -- Monster - Throwing Knife (Fire Trail)
	[33474] = {base_speed = 3},    -- Ancient Amani Longbow
	[33491] = {base_speed = 2.9},    -- Tuskbreaker
	[33764] = {base_speed = 1.9},    -- Vengeful Gladiator's Touch of Defeat
	[33765] = {base_speed = 1.9},    -- Vengeful Gladiator's War Edge
	[33790] = {base_speed = 2},    -- Monster - Axe, Horde B03 Copper (Thrown)
	[33991] = {base_speed = 2.7},    -- Monster - Zul'Aman - Bow - Amani'shi Handler
	[34039] = {base_speed = 6},    -- Bow of Unusual Slowness
	[34059] = {base_speed = 1.9},    -- Vengeful Gladiator's Baton of Light
	[34066] = {base_speed = 1.9},    -- Vengeful Gladiator's Piercing Touch
	[34098] = {base_speed = 2},    -- Monster - Gun, Blood Elf Red
	[34196] = {base_speed = 3},    -- Golden Bow of Quel'Thalas
	[34263] = {base_speed = 2},    -- Monster - Bow, Blood Elf A01 Black
	[34264] = {base_speed = 2},    -- Monster - Bow, Blood Elf A01 Blue
	[34265] = {base_speed = 2},    -- Monster - Bow, Blood Elf A01 Orange
	[34266] = {base_speed = 2},    -- Monster - Bow, Blood Elf A01 Red
	[34267] = {base_speed = 2},    -- Monster - Bow, Blood Elf A01 Yellow
	[34268] = {base_speed = 2},    -- Monster - Bow, Blood Elf B01 Orange
	[34269] = {base_speed = 2},    -- Monster - Bow, Blood Elf B01 Black
	[34270] = {base_speed = 2},    -- Monster - Bow, Blood Elf B01 Red
	[34271] = {base_speed = 2},    -- Monster - Bow, Blood Elf C01 Default
	[34272] = {base_speed = 2},    -- Monster - Bow, Blood Elf C01 Black
	[34273] = {base_speed = 2},    -- Monster - Bow, Blood Elf C01 Orange
	[34274] = {base_speed = 2},    -- Monster - Bow, Blood Elf C01 Red
	[34275] = {base_speed = 2},    -- Monster - Bow, Blood Elf C01 Silver
	[34276] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Default
	[34277] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Black
	[34278] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Gold
	[34279] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Orange
	[34280] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Red
	[34281] = {base_speed = 2},    -- Monster - Bow, Blood Elf D01 Silver
	[34312] = {base_speed = 2},    -- Monster - Crossbow, Draenei A01
	[34313] = {base_speed = 2},    -- Monster - Crossbow, Draenei A01 Brown
	[34314] = {base_speed = 2},    -- Monster - Crossbow, Draenei A01 Gold
	[34315] = {base_speed = 2},    -- Monster - Crossbow, Draenei A01 Orange
	[34316] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Blue
	[34317] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Blue Trim
	[34318] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Brown
	[34320] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Green Trim
	[34321] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Grey Trim
	[34322] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Purple
	[34323] = {base_speed = 2},    -- Monster - Crossbow, Draenei A02 Red Trim
	[34325] = {base_speed = 2},    -- Monster - Crossbow, Outland Raid D01
	[34326] = {base_speed = 2},    -- Monster - Crossbow, Outland Raid D04
	[34327] = {base_speed = 2},    -- Monster - Crossbow, Outland Raid D05
	[34328] = {base_speed = 2},    -- Monster - Crossbow, Outland Raid D06
	[34334] = {base_speed = 2.7},    -- Thori'dal, the Stars' Fury
	[34347] = {base_speed = 1.5},    -- Wand of the Demonsoul
	[34348] = {base_speed = 1.5},    -- Wand of Cleansing Light
	[34349] = {base_speed = 2},    -- Blade of Life's Inevitability
	[34418] = {base_speed = 1.8},    -- Scrying Wand
	[34419] = {base_speed = 3},    -- Thorium Flight Blade
	[34529] = {base_speed = 3},    -- Vengeful Gladiator's Longbow
	[34530] = {base_speed = 3},    -- Vengeful Gladiator's Rifle
	[34603] = {base_speed = 2},    -- Distracting Blades
	[34622] = {base_speed = 2.2},    -- Spinesever
	[34674] = {base_speed = 2.6},    -- Truestrike Crossbow
	[34783] = {base_speed = 2.2},    -- Nightstrike
	[34873] = {base_speed = 2},    -- Monster - Sunwell Raid - Bow, D01 Green
	[34892] = {base_speed = 2.8},    -- Crossbow of Relentless Strikes
	[34985] = {base_speed = 1.9},    -- Brutal Gladiator's Baton of Light
	[35018] = {base_speed = 3},    -- Brutal Gladiator's Heavy Crossbow
	[35047] = {base_speed = 3},    -- Brutal Gladiator's Longbow
	[35065] = {base_speed = 1.9},    -- Brutal Gladiator's Piercing Touch
	[35075] = {base_speed = 3},    -- Brutal Gladiator's Rifle
	[35107] = {base_speed = 1.9},    -- Brutal Gladiator's Touch of Defeat
	[35108] = {base_speed = 1.9},    -- Brutal Gladiator's War Edge
	[186050] = {base_speed = 1.4},    -- Communal Wand
	[186056] = {base_speed = 2.7},    -- Communal Bow
	[186069] = {base_speed = 1.8}    -- Communal Knives
}
