local SPEC_WARRIOR_ARMS = 71
local SPEC_WARRIOR_FURY = 72
local SPEC_WARRIOR_PROT = 73

LCT_SpellData[100] = {
	other = true,
	name = "Charge",
	buff = 100,
	duration = 20,
	class = "WARRIOR",
}

LCT_SpellData[355] = {
	talent = true,
	other = true,
	name = "Taunt",
	buff = 355,
	duration = 8,
	class = "WARRIOR",
}

LCT_SpellData[871] = {
	defensive = true,
	buff = 871,
	class = "WARRIOR",
	name = "Shield Wall",
	charges = 1,
	duration = 210,
}

LCT_SpellData[1160] = {
	defensive = true,
	name = "Demoralizing Shout",
	buff = 1160,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[1161] = {
	other = true,
	buff = 1161,
	class = "WARRIOR",
	name = "Challenging Shout",
	talent = true,
	duration = 120,
}

LCT_SpellData[1719] = {
	offensive = true,
	name = "Recklessness",
	buff = 1719,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[2565] = {
	charges = { [SPEC_WARRIOR_PROT] = 2, [default] = 1, },
	defensive = true,
	name = "Shield Block",
	buff = 132404,
	duration = 16,
	class = "WARRIOR",
}

LCT_SpellData[3411] = {
	counterCC = true,
	name = "Intervene",
	buff = 3411,
	duration = 30,
	class = "WARRIOR",
}

LCT_SpellData[5246] = {
	cc = true,
	name = "Intimidating Shout",
	buff = 5246,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[6544] = {
	other = true,
	buff = 202164,
	class = "WARRIOR",
	name = "Heroic Leap",
	charges = 1,
	duration = 45,
}

LCT_SpellData[6552] = {
	interrupt = true,
	name = "Pummel",
	buff = 6552,
	duration = 15,
	class = "WARRIOR",
}

LCT_SpellData[12323] = {
	other = true,
	name = "Piercing Howl",
	buff = 12323,
	duration = 30,
	class = "WARRIOR",
}

LCT_SpellData[12975] = {
	defensive = true,
	name = "Last Stand",
	buff = 12975,
	duration = 180,
	class = "WARRIOR",
}

LCT_SpellData[18499] = {
	counterCC = true,
	buff = 18499,
	class = "WARRIOR",
	name = "Berserker Rage",
	talent = true,
	duration = 60,
}

LCT_SpellData[23920] = {
	counterCC = true,
	buff = 23920,
	class = "WARRIOR",
	name = "Spell Reflection",
	charges = 1,
	duration = { [SPEC_WARRIOR_PROT] = 20, [default] = 25, },
}

LCT_SpellData[46968] = {
	cc = true,
	name = "Shockwave",
	buff = 46968,
	duration = 40,
	class = "WARRIOR",
}

LCT_SpellData[64382] = {
	other = true,
	name = "Shattering Throw",
	buff = 64382,
	duration = 180,
	class = "WARRIOR",
}

LCT_SpellData[97462] = {
	raidDefensive = true,
	name = "Rallying Cry",
	buff = 97463,
	duration = 180,
	class = "WARRIOR",
}

LCT_SpellData[107570] = {
	cc = true,
	name = "Storm Bolt",
	buff = 107570,
	duration = 30,
	class = "WARRIOR",
}

LCT_SpellData[107574] = {
	offensive = true,
	name = "Avatar",
	buff = 107574,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[118038] = {
	defensive = true,
	name = "Die by the Sword",
	buff = 118038,
	duration = 120,
	class = "WARRIOR",
}

LCT_SpellData[167105] = {
	offensive = true,
	buff = 167105,
	class = "WARRIOR",
	name = "Colossus Smash",
	talent = true,
	duration = 45,
}

LCT_SpellData[184364] = {
	defensive = true,
	name = "Enraged Regeneration",
	buff = 184364,
	duration = 120,
	class = "WARRIOR",
}

LCT_SpellData[198817] = {
	offensive = true,
	name = "Sharpen Blade",
	buff = 198817,
	duration = 30,
	class = "WARRIOR",
}

LCT_SpellData[202168] = {
	defensive = true,
	name = "Impending Victory",
	buff = 202168,
	duration = 25,
	class = "WARRIOR",
}

LCT_SpellData[205800] = {
	other = true,
	name = "Oppressor",
	buff = 205800,
	duration = 20,
	class = "WARRIOR",
}

LCT_SpellData[206572] = {
	other = true,
	name = "Dragon Charge",
	buff = 206572,
	duration = 20,
	class = "WARRIOR",
}

LCT_SpellData[213871] = {
	externalDefensive = true,
	name = "Bodyguard",
	buff = 213871,
	duration = 15,
	class = "WARRIOR",
}

LCT_SpellData[227847] = {
	offensive = true,
	name = "Bladestorm",
	buff = 227847,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[228920] = {
	offensive = true,
	buff = 228920,
	class = "WARRIOR",
	name = "Ravager",
	charges = 1,
	duration = 90,
}

LCT_SpellData[236077] = {
	disarm = true,
	name = "Disarm",
	buff = 236077,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[236273] = {
	defensive = true,
	name = "Duel",
	buff = 236273,
	duration = 60,
	class = "WARRIOR",
}

LCT_SpellData[236320] = {
	counterCC = true,
	name = "War Banner",
	buff = 236321,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[260643] = {
	offensive = true,
	name = "Skullsplitter",
	buff = 260643,
	duration = 21,
	class = "WARRIOR",
}

LCT_SpellData[260708] = {
	specID = { 71 },
	offensive = true,
	name = "Sweeping Strikes",
	buff = 260708,
	duration = 30,
	class = "WARRIOR",
}

LCT_SpellData[262161] = {
	offensive = true,
	name = "Warbreaker",
	buff = 262161,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[329038] = {
	other = true,
	name = "Bloodrage",
	buff = 329038,
	duration = 20,
	class = "WARRIOR",
}

LCT_SpellData[376079] = {
	specID = { 376079, 321076 },
	offensive = true,
	name = "Spear of Bastion",
	buff = 376079,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[383762] = {
	dispel = true,
	name = "Bitter Immunity",
	buff = 383762,
	duration = 180,
	class = "WARRIOR",
}

LCT_SpellData[384100] = {
	counterCC = true,
	name = "Berserker Shout",
	buff = 384100,
	duration = 60,
	class = "WARRIOR",
}

LCT_SpellData[384110] = {
	offensive = true,
	name = "Wrecking Throw",
	buff = 384110,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[384318] = {
	offensive = true,
	name = "Thunderous Roar",
	buff = 384318,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[385059] = {
	offensive = true,
	name = "Odyn's Fury",
	buff = 385059,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[385952] = {
	cc = true,
	name = "Shield Charge",
	buff = 385952,
	duration = 45,
	class = "WARRIOR",
}

LCT_SpellData[386071] = {
	interrupt = true,
	name = "Disrupting Shout",
	buff = 386071,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[386394] = {
	defensive = true,
	name = "Battle-Scarred Veteran",
	buff = 386394,
	duration = 180,
	class = "WARRIOR",
}

LCT_SpellData[392966] = {
	defensive = true,
	name = "Spell Block",
	buff = 392966,
	duration = 90,
	class = "WARRIOR",
}

LCT_SpellData[401150] = {
	offensive = true,
	name = "Avatar",
	buff = 401150,
	duration = 90,
	class = "WARRIOR",
}
