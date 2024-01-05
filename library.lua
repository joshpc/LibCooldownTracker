--[[
	Callbacks:
		LCT_CooldownUsed(unitid, spellId)
		LCT_CooldownsReset(unit)

	Functions:
		lib:RegisterUnit(unitid)
		lib:UnregisterUnit(unitid)
		tpu = lib:GetUnitCooldownInfo(unitid, spellId, used_start, used_end, cooldown_start)
		for spellId, spell_data in lib:IterateCooldowns(class, specID, race) do
		spell_data = lib:GetCooldownData(spellId)
		spells_data = lib:GetCooldownsData()
]]

local version = 10
local lib = LibStub:NewLibrary("LibCooldownTracker-2.0", version)
local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local LGIST = IsRetail and LibStub:GetLibrary("LibGroupInSpecT-1.1")
local fn = LibStub("LibFunctional-1.0")

local keys, map, filter, any = fn.keys, fn.map, fn.filter, fn.any

if not lib then return end

-- upvalues
local pairs, type, next, select, assert, unpack = pairs, type, next, select, assert, unpack
local tinsert, tremove = table.insert, table.remove
local GetTime, UnitGUID, IsInInstance = GetTime, UnitGUID, IsInInstance

lib.frame = lib.frame or CreateFrame("Frame")
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)

-- init event handler
local events = {}
do
	lib.frame:SetScript("OnEvent",
		function(self, event, ...)
			return events[event](lib, event, ...)
		end)
end

-- lookup tables
local class_spellData = {}
local race_spellData = {}
local item_spellData = {}
local pvp_spellData = {}

-- generate lookup tables
do
	for spellId, spellData in pairs(LCT_SpellData) do
		if type(spellData) == "table" then
			local name, _, icon = GetSpellInfo(spellId)
			if not name then
				DEFAULT_CHAT_FRAME:AddMessage("LibCooldownTracker-2.0: bad spellId for " .. (spellData.class or spellData.race or "ITEM") .. ": " .. spellId)
				LCT_SpellData[spellId] = nil
			else
				-- add name and icon
				spellData.name = name
				if not spellData.icon then
					if type(spellData.item) == 'number' then
						spellData.icon = GetItemIcon(spellData.item)
					else
						spellData.icon = icon
					end
				end

				-- add required aura name
				if spellData.requires_aura then
					spellData.requires_aura_name = GetSpellInfo(spellData.requires_aura)
					if not spellData.requires_aura_name then
						DEFAULT_CHAT_FRAME:AddMessage("LibCooldownTracker-2.0: bad aura spellId: " .. spellData.requires_aura)
					end
				end

				-- convert specID list into lookups table
				if spellData.specID then
					local specs = {}
					for i = 1, #spellData.specID do
						specs[spellData.specID[i]] = true
					end
					spellData.specID_table = specs
				end

				-- insert into lookup tables
				if spellData.class then
					class_spellData[spellData.class] = class_spellData[spellData.class] or {}
					class_spellData[spellData.class][spellId] = spellData
				end
				if spellData.race then
					race_spellData[spellData.race] = race_spellData[spellData.race] or {}
					race_spellData[spellData.race][spellId] = spellData
				end
				if spellData.item then
					item_spellData[spellId] = spellData
				end
				if spellData.pvp_trinket then
					pvp_spellData[spellId] = spellData
				end
			end
		end
	end
end

local SpellData = LCT_SpellData
LCT_SpellData = nil

-- state
lib.guid_to_unitid = lib.guid_to_unitid or {} -- [guid] = unitid
lib.tracked_players = lib.tracked_players or {} --[[
	[unitid][spellId] = {
		["cooldown_start"] = time,
		["cooldown_end"] = time,
		["used_start"] = time,
		["used_end"] = time,
		["detected"] = boolean,
		[EVENT] = time
	}
]]
lib.registered_units = lib.registered_units or {} -- [unitid] = count

local function RemoveGUID(unit)
	-- find and delete old references to that unit
	for guid, unitid in pairs(lib.guid_to_unitid) do
		if unitid == unit then
			lib.guid_to_unitid[guid] = nil
		end
	end
end

local function UpdateGUID(unit)
	RemoveGUID(unit)

	local guid = UnitGUID(unit)
	if guid then lib.guid_to_unitid[guid] = unit end

	local pet_guid = UnitGUID(unit .. "pet")
	if pet_guid then lib.guid_to_unitid[pet_guid] = unit end
end

-- simple timer used for updating number of charges
-- timers are stored ordered by their firing time so only the first
-- timer on the list is checked in the OnUpdate
local timers = {}
local timer_frame

local function Timer_OnUpdate()
	local t1 = timers[1]
	if t1 and GetTime() >= t1.time then
		tremove(timers, 1)
		t1.func(unpack(t1.args))
		if #timers == 0 then
			lib.frame:SetScript("OnUpdate", nil)
		end
	end
end

local function SetTimer(time, func, ...)
	local pos = 1
	while pos <= #timers do
		if timers[pos].time >= time then
			break
		end
		pos = pos + 1
	end

	tinsert(timers, pos, { time = time, func = func, args = { ... } })

	if #timers == 1 then
		lib.frame:SetScript("OnUpdate", Timer_OnUpdate)
	end

	return pos
end

local function ClearTimers()
	lib.frame:SetScript("OnUpdate", nil)
	timers = {}
end

local function GetCooldownTime(spellId, unit)
	local spellData = SpellData[spellId]
	local time = spellData.cooldown

	local tps = lib.tracked_players[unit][spellId]
	if tps and tps.cooldown then
		time = tps.cooldown
	end
	
	return time
end

local function AuraByIdPredicate(auraNameToFind, _, _, ...)
	return auraNameToFind == select(10, ...)
end

local function FindAuraById(auraId, unit, filter)
	return AuraUtil.FindAura(AuraByIdPredicate, unit, filter, auraId)
end 

local function AddCharge(unit, spellId)
	local tps = lib.tracked_players[unit][spellId]
	if not tps then
		return
	end
	tps.charges = tps.charges + 1
	lib.callbacks:Fire("LCT_CooldownUsed", unit, spellId)

	-- schedule another timer if there are more charges in cooldown
	if tps.max_charges and tps.charges < tps.max_charges then
		local now = GetTime()
		local spellData = SpellData[spellId]
		tps.cooldown_start = now
		tps.cooldown_end = now + GetCooldownTime(spellId, unit)
		tps.charge_timer = SetTimer(tps.cooldown_end, AddCharge, unit, spellId)
	else
		tps.charge_timer = false
	end
end

local function check_reduce(reduce, unit, spellId)
	if reduce.spell_cast_buff then
		if not FindAuraById(spellId, unit) then
			return false
		end
	end

	local buffs = reduce.buffs or reduce.buff and { reduce.buff }
	if buffs then
		for buff in pairs(buffs) do
			if not FindAuraById(buff, unit) then
				return false
			end
		end
	end

	-- TODO: Re-add specialization check

	return true
end

local function CooldownEvent(event, unit, spellId)
	-- TODO: This function can likely be simplified or at the very least broken up into functional units

	if not lib:IsUnitRegistered(unit) then return end -- We don't care about this event

	local spellData = SpellData[spellId]
	if type(spellData) == "number" then
		spellId = spellData
		spellData = SpellData[spellId]
	end

	if not spellData then return end -- TODO: Log unknown spellId event. Although this may be noisy?

	if spellData.ignore_cooldown_event then
		return
	end

	local now = GetTime()
	if not lib.tracked_players[unit] then
		lib.tracked_players[unit] = {}
	end
	local tpu = lib.tracked_players[unit]

	if tpu[spellId] then
		-- check if the same spell cast was detected recently
		-- if so, we assume that the first detection time is more accurate and ignore this one
		-- this can happen because we listen to both UNIT_SPELLCAST_SUCCEEDED and SPELL_CAST_SUCCESS from COMBAT_LOG_EVENT_UNFILTERED
		-- and because both SPELL_CAST_SUCCESS and SPELL_AURA_APPLIED are considered events for cooldown uses
		local margin = 1
		if (event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and
		   ((event ~= "UNIT_SPELLCAST_SUCCEEDED" and tpu[spellId]["UNIT_SPELLCAST_SUCCEEDED"] and (tpu[spellId]["UNIT_SPELLCAST_SUCCEEDED"] + margin) > now) or
			(event ~= "SPELL_AURA_APPLIED"       and tpu[spellId]["SPELL_AURA_APPLIED"]       and (tpu[spellId]["SPELL_AURA_APPLIED"]       + margin) > now) or
			(event ~= "SPELL_CAST_SUCCESS"       and tpu[spellId]["SPELL_CAST_SUCCESS"]       and (tpu[spellId]["SPELL_CAST_SUCCESS"]       + margin) > now)) then
			return
		end

		-- register event time
		tpu[spellId][event] = now
	else
		tpu[spellId] = {
			charges = spellData.charges,
			max_charges = spellData.charges,
			charges_detected = spellData.charges and true or false,
			[event] = now,
		}
	end

	local tps = tpu[spellId]

	-- find what actions are needed
	local used_start, used_end, cooldown_start
	local buff_was_full_duration = false
	if spellData.cooldown_starts_on_dispel then
		if event == "SPELL_DISPEL" then
			used_start = true
			cooldown_start = true
		end
	elseif spellData.cooldown_starts_on_aura_duration then
		if event == "SPELL_AURA_APPLIED" then
			local n, _, _, _, aura_duration = FindAuraById(spellId, unit)
			-- Some leeway... If the aura isn't present, pretend the spell has actually been used.
			if not aura_duration or aura_duration >= spellData.duration - 2 then
				used_start = true
				cooldown_start = true
			end
		end
	elseif spellData.cooldown_starts_on_aura_fade then
		if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
			used_start = true
		elseif event == "SPELL_AURA_REMOVED" then
			cooldown_start = true
		end
	else
		if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
			used_start = true
			cooldown_start = true
		elseif event == "SPELL_AURA_REMOVED" then
			used_end = true
			local applied = tpu[spellId]["SPELL_AURA_APPLIED"]
			buff_was_full_duration = applied and spellData.duration and (now - applied) >= (spellData.duration - 0.5) -- 0.5 for leeway
		end
	end

	-- Only detect the spell if it's actually used (i.e. not if it's just a random proc)
	if (used_start or used_end or cooldown_start) and not tpu[spellId].detected then
		-- XXX use DetectSpell() here instead?
		tpu[spellId].detected = true
	end

	-- apply actions
	if used_start then
		tps.used_start = now
		tps.used_end = duration and (now + duration)

		-- is the cooldown still in progress?
		local on_cd = tps.cooldown_end and (tps.cooldown_end - 2) > now
		local use_lower_cd = false

		-- remove charge
		if tps.charges then
			if tps.charges > 0 then
				tps.charges = tps.charges - 1
				-- if cooldown is still in progress and the spell can optionally have charges (with a talent), then it must have charges
		
				if not tps.charges_detected and on_cd then
					tps.charges_detected = true
				else
					-- We'd go into negative charges. Adjust timer
					use_lower_cd = true
				end
			else
				-- No charges left.
				use_lower_cd = true
			end
		elseif on_cd then
			-- No potential charges, yet the spell was cast while on CD? Adjust timer
			use_lower_cd = true
		end

		-- Did we figure out we got our timer wrong?
		if use_lower_cd and spellData.opt_lower_cooldown then
			tps.cooldown = spellData.opt_lower_cooldown
		end

		if spellData.restore_charges then
			for i = 1, #spellData.restore_charges do
				local respellId = spellData.restore_charges[i]
				local respellData = SpellData[respellId]
				
				if not tpu[respellId] then
					-- V: if we have to *detect* the cooldown, just use the max number of charges
					--    also, use charges by default, not only optional charges (not sure if the spell only has optional charges)

					tpu[respellId] = {
						charges = respellData.charges or respellData.opt_charges,
						max_charges = respellData.charges or respellData.opt_charges,
					}
				else
					-- TODO: might have to cancel some timers
					tpu[respellId].charges = (tpu[respellId].charges or 0) + 1
				end
				
				tpu[respellId].charges_detected = true
			end
		end

		-- reset other cooldowns (Cold Snap, Preparation)
		if spellData.resets then
			for i = 1, #spellData.resets do
				local rspellId = spellData.resets[i]
				if tpu[rspellId] then
					tpu[rspellId].cooldown_start = 0
					tpu[rspellId].cooldown_end = 0
				end
			end
		end
	end

	if used_end then
		tps.used_end = now
		-- A spell might have a different cooldown if its buff stayed on for the whole duration (and didnt proc before) 
		if tps.cooldown_end and buff_was_full_duration and spellData.cooldown_on_full_aura_duration then
			tps.cooldown_end = now + spellData.cooldown_on_full_aura_duration
		end
	end

	if cooldown_start then
		-- if the spell has charges and the cooldown is already in progress, it does not need to be reset
		if not tps.charges or not tps.cooldown_end or tps.cooldown_end <= now then
			local cooldown_time = GetCooldownTime(spellId, unit)
			tps.cooldown_start = cooldown_time and now
			tps.cooldown_end = cooldown_time and (now + cooldown_time)

			-- set charge timer
			if tps.charges and not tps.charge_timer then
				tps.charge_timer = SetTimer(tps.cooldown_end, AddCharge, unit, spellId)
			end

			-- V: set other cooldown(s)
			local sets_cooldowns = spellData.sets_cooldown or spellData.sets_cooldown and { spellData.sets_cooldown } or {}

			for i = 1, #sets_cooldowns do
				local cd = sets_cooldowns[i]
				local cspellId = cd.spellId
				local cspellData = SpellData[cspellId]
				if cspellData and ((tpu[cspellId] and tpu[cspellId].detected) or (not cspellData.talent)) then
					if not tpu[cspellId] then
						tpu[cspellId] = {}
					end
					
					if not tpu[cspellId].cooldown_end or (tpu[cspellId].cooldown_end < (now + cd.cooldown)) then
						tpu[cspellId].cooldown_start = now
						tpu[cspellId].cooldown_end = now + cd.cooldown
						tpu[cspellId].used_start = tpu[cspellId].used_start or 0
						tpu[cspellId].used_end = tpu[cspellId].used_end or 0
					end
				end
			end
		end
	end

	lib.callbacks:Fire("LCT_CooldownUsed", unit, spellId, used_start, used_end, cooldown_start)
end

local function enable()
	lib.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	lib.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	lib.frame:RegisterEvent("UNIT_NAME_UPDATE")
	lib.frame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
	lib.frame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
	lib.frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
	if IsRetail then
			lib.frame:RegisterEvent("PVP_MATCH_ACTIVE")
	end

	lib.tracked_players = {}
	lib.guid_to_unitid = {}

	for unitid in pairs(lib.registered_units) do
		UpdateGUID(unitid)
	end

	if LGIST then
		LGIST.RegisterCallback(lib, "GroupInSpecT_Update")
	end
end

local function disable()
	lib.frame:UnregisterAllEvents()
end

-- Removes all the talent spells from a tracked unit
function lib:ClearTalents(unit)
	local tpu = lib.tracked_players[unit]
	if not tpu then return end

	-- find out which detected spells are talents/items/trinkets, and un-detect them
	local remove_spells = filter(keys(tpu), function (k)
		local spell = SpellData[k]
		return tpu[k].detected and type(spell) == "table" and (spell.talent or spell.item and spell.pvp_trinket)
	end)

	for i = 1, #remove_spells do
		tpu[remove_spells[i]] = nil
	end
end

local function GetPartyUnit(unit, guid)
	if unit == "player" then return unit end
	if string.sub(unit, 1, 5) == "party" then return unit end
	if string.sub(unit, 1, 4) == "raid" then
		-- XXX: this is a very ugly for, replace it with *something else*
		for i = 1, GetNumGroupMembers() do
			if UnitGUID("party"..i) == guid then return "party"..i end
		end
	end
end

function lib:GroupInSpecT_Update(event, guid, raw_unit, info)
	local unit = GetPartyUnit(raw_unit, guid)
	if not unit then return end

	local tpu = lib.tracked_players[unit]
	if not tpu then lib.tracked_players[unit] = {} end

	lib:ClearTalents(unit)

	-- we didn't detect any talent. wait for follow-up message.
	if not next(info.talents) then
		return
	end

	for talentId, talent in pairs(info.talents) do
		-- XXX only detect spells if SpellData[talent.spell_id]?
		lib:DetectSpell(unit, talent.spell_id)

		-- TODO have some kind of LCT_TalentData so that we can detect charges and other stuff
	end
end

function lib.callbacks:OnUsed(target, event)
	if event == "LCT_CooldownUsed" then
		enable()
	end
end

function lib.callbacks:OnUnused(target, event)
	if event == "LCT_CooldownUsed" then
		disable()
	end
end

--- Registers an unit to be tracked by the library.
-- @param unitid The unitid to register.
function lib:RegisterUnit(unitid)
	local count = (lib.registered_units[unitid] or 0) + 1
	if count == 1 then
		UpdateGUID(unitid)
	end
	lib.registered_units[unitid] = count
	return count
end

--- Unregisters an unit.
-- While the same unit may be registered more than once, it is important that
-- UnregisterUnit is called exactly once for each call to RegisterUnit.
-- @param unitid The unitid to unregister.
function lib:UnregisterUnit(unitid)
	assert(lib.registered_units[unitid] ~= nil, "Attempting to unregister a unit not registered")

	local count = lib.registered_units[unitid] - 1
	if count == 0 then
		lib.registered_units[unitid] = nil
		RemoveGUID(unitid)
	else
		lib.registered_units[unitid] = count
	end
	return count
end

function lib:IsUnitRegistered(unitid)
	return lib.registered_units[unitid]
end

--- Returns a table with the state of a unit's cooldown, or nil if there is no state stored about it.
-- @param unitid The unit unitid.
-- @param spellId The cooldown spellId.
-- @usage
-- local tracked = lib:GetUnitCooldownInfo(unitid, spellId)
-- if tracked then
--     print(tracked.cooldown_start) -- times are based on GetTime()
--     print(tracked.cooldown_end)
--     print(tracked.used_start)
--     print(tracked.used_end)
--     print(tracked.detected) -- use this to check if the unit has used this spell before (useful for detecting talents)
-- end
function lib:GetUnitCooldownInfo(unitid, spellId)
	local tpu = lib.tracked_players[unitid]
	return tpu and tpu[spellId]
end

function lib:DetectSpell(unit, spellId)
	if not spellId then
		return
	end

	if not lib.tracked_players[unit] then
		lib.tracked_players[unit] = {}
	end

	local spell = lib.tracked_players[unit][spellId]
	if not spell then
		lib.tracked_players[unit][spellId] = {
			detected = true
		}
	elseif not spell.detected then
		spell.detected = true
	end

	lib.callbacks:Fire("LCT_CooldownDetected", unit, spellId)
end

--- Returns the raw data of all the cooldowns. See the cooldowns_*.lua data files for more details about its structure.
function lib:GetCooldownsData()
	return SpellData
end

--- Returns the raw data of a specified cooldown spellId.
-- @param spellId The cooldown spellId.
function lib:GetCooldownData(spellId)
	return SpellData[spellId]
end

local function CooldownIterator(state, spellId)
	while true do
		spellId = next(state.data_source, spellId)
		if spellId == nil then
			return
		end
		local spellData = state.data_source[spellId]
		-- ignore references to other spells
		if type(spellData) ~= "number" then
			if state.class and state.class == spellData.class then
        if spellData.specID_table then
          if state.specID and spellData.specID_table[state.specID] then
            -- add spec
            return spellId, spellData
          end
				else
					-- add base
					return spellId, spellData
				end
			end

			if state.race and state.race == spellData.race then
				-- return racial
				return spellId, spellData
			end

			if spellData.item or spellData.pvp_trinket then
				-- return item or pvp trinket
				if not spellData.race or spellData.race == state.race  then
					return spellId, spellData
				end
			end
		end
	end
end

-- uses lookup tables
local function FastCooldownIterator(state, spellId)
	local spellData
	-- class
	if state.class then
		if state.data_source then
			spellId, spellData = CooldownIterator(state, spellId)
		end

		if spellId then
			return spellId, spellData
		else
			-- do race next
			state.data_source = race_spellData[state.race]
			state.class = nil
			spellId = nil
		end
	end

	-- race
	if state.race then
		if state.data_source then
			spellId, spellData = CooldownIterator(state, spellId)
		end

		if spellId then
			return spellId, spellData
		else
			-- do items next
			state.data_source = item_spellData
			state.race = nil
			spellId = nil
		end
	end

	-- item
	if state.item then
		if state.data_source then
			spellId, spellData = CooldownIterator(state, spellId)
		end

		if spellId then
			return spellId, spellData
		else
			-- do pvp next
			state.data_source = pvp_spellData
			state.item = nil
			spellId = nil
		end
	end

	-- pvp
	if state.pvp then
		if state.data_source then
			spellId, spellData = CooldownIterator(state, spellId)
		end
		if spellId then
			return spellId, spellData
		else
			state.data_source = nil
			state.pvp = nil
			spellId = nil
		end
	end
end

--- Iterates over the cooldowns that apply to a unit of the specified //class//, //specID// and //race//.
-- @param class The unit class. Can be nil.
-- @param specID The unit talent spec ID. Can be nil.
-- @param race The unit race. Can be nil.
function lib:IterateCooldowns(class, specID, race)
	local state = {}
	state.class = class
	state.specID = specID
	state.race = race or ""
	state.item = true
	state.pvp = true

	if class then
		state.data_source = class_spellData[class]

		return FastCooldownIterator, state
	else
		state.data_source = SpellData
		return CooldownIterator, state
	end
end

function events:PVP_MATCH_ACTIVE()
	events:PLAYER_ENTERING_WORLD()
end

function events:PLAYER_ENTERING_WORLD()
	local isInInstance = IsInInstance()

	-- reset cooldowns if we're entering an instance
  	-- this might be incorrect (only bgs & arenas reset cooldowns), but is important to reset talents when zoning in
	if isInInstance then
		ClearTimers()
		for unit in pairs(lib.tracked_players) do
			lib.tracked_players[unit] = nil
			lib.callbacks:Fire("LCT_CooldownsReset", unit)
		end
	end
end

function events:UNIT_SPELLCAST_SUCCEEDED(event, unit, lineID, spellId)
	CooldownEvent(event, unit, spellId)
end

function events:CombatLogEvent(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType)
	-- check unit
	local unit = lib.guid_to_unitid[sourceGUID]
	if not unit then return end

	if event == "SPELL_DISPEL" or event == "SPELL_AURA_REMOVED" or event == "SPELL_AURA_APPLIED" or event == "SPELL_CAST_SUCCESS" then
		CooldownEvent(event, unit, spellId)
	end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(event)
	events:CombatLogEvent(event, CombatLogGetCurrentEventInfo())
end

function events:UNIT_NAME_UPDATE(event, unit)
	UpdateGUID(unit)
end

function events:ARENA_CROWD_CONTROL_SPELL_UPDATE(event, unit, spellID)
	-- V: sometimes we receive such an event for "nameplateX" or "focus"
	if string.sub(unit, 1, 5) ~= "arena" then return end
	if not spellID then return end
  	
	lib:DetectSpell(unit, spellID)
	lib.callbacks:Fire("LCT_CooldownDetected", unit, spellId)
end

function events:ARENA_OPPONENT_UPDATE(event, unit, unitEvent)
	if unitEvent == "seen" then
		C_PvP.RequestCrowdControlSpell(unit)
	end
end

function events:ARENA_COOLDOWNS_UPDATE(event, unit)
	if string.sub(unit, 1, 5) ~= "arena" then return end
  	local spellId, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
  	if not spellId then
    	C_PvP.RequestCrowdControlSpell(unit)
    	return
  	end
  
	lib:DetectSpell(unit, spellId)
	lib.callbacks:Fire("LCT_CooldownDetected", unit, spellId)
  	
	if not startTime or not duration then return end

  	lib.tracked_players[unit][spellId].cooldown_start = (startTime / 1000)
  	lib.tracked_players[unit][spellId].cooldown_end = (startTime / 1000) + (duration / 1000)
	lib.callbacks:Fire("LCT_CooldownUsed", unit, spellId)
end
