-- When using this script, obtain the latest spell_db info. The expected format is as follows:
-- E.spell_db = {
--   ["WARRIOR"] = {
--		{ ["class"]="WARRIOR",["type"]="defensive",["buff"]=236273,["spec"]=true,["name"]="Duel",["duration"]=60,["icon"]=1455893,["spellID"]=236273, },
--      ... more warrior abilities
--   }, 
--   ["ROGUE"] = {
--		{ ["class"]="ROGUE",["type"]="cc",["buff"]=207736,["spec"]=true,["name"]="Shadowy Duel",["duration"]=120,["icon"]=1020341,["spellID"]=207736, },
--      ... more rogue abilities
--   },
--  ... more classes
-- }
--
-- Then simply run: `lua converter.lua > out.txt` and populate the cooldowns_ files.

E = {}
E.spell_db = {}

function tableToStringKey(key)
	if type(key) == "number" then
		return "[" .. key .. "]"
	else
		return key
	end
end

function tableToString(t, indent)
    local str = "{ "
    for key, value in pairs(t) do
        if type(value) == "table" then
            str = str .. tableToStringKey(key) .. " = " .. tableToString(value) .. ", "
        else
            str = str .. tableToStringKey(key) .. " = " .. tostring(value) .. ", "
        end
    end
    return str .. "}"
end

local booleanKeys = { "defensive", "offensive", }

local ignoredKeys = {
	["spellID"] = true,
	["icon"] = true
}
local uniqueKeys = {}

local function getSortedKeys(t)
	keyMap = {}
	spellIDs = {}
	for k, v in pairs(t) do
		spellID = v["spellID"]
		keyMap[spellID] = k
		table.insert(spellIDs, spellID)
	end
	
	table.sort(spellIDs)

	sortedKeys = {}
	for _, spellID in pairs(spellIDs) do
		table.insert(sortedKeys, keyMap[spellID])
	end
	return sortedKeys
end

local function getFirstValue(t)
	for _, v in pairs(t) do
		return v
	end
end

for className, spells in pairs(E.spell_db) do
	keys = getSortedKeys(spells)
	print("============ " .. className .. " ============")
    for _, spellKey in pairs(keys) do
		spell = spells[spellKey]

		print("LCT_SpellData[" .. spell["spellID"] .. "] = {")
		for key, value in pairs(spell) do
			uniqueKeys[key] = true

			-- Map to something more logical
			if key == "duration" then
				key = "cooldown"
			end

			if ignoredKeys[key] then
				-- Do nothing
			elseif key == "talent" then
				print("\ttalent = true,")
			elseif key == "type" then
				print("\t" .. value .. " = true,")
			elseif key == "spec" then
				if type(value) == "boolean" and value == true then
					-- Do nothing
				elseif type(value) == "table" then
					print("\tspecID = { " .. table.concat(value, ", ") .. " },")
				else
					print("\tspecID = { " .. value .. " },")
				end
			elseif type(value) == "boolean" then
				print("\t" .. key .. " = " .. tostring(value) .. ",")
			elseif type(value) == "table" then
				if key == "cooldown" then
					--TODO: This currently flattens the cooldown value. This isn't great because we ignore things where certain specs have lower CDs.
					print("\t" .. key .. " = " .. (value["default"] or getFirstValue(value) or 0) .. ",")
				else
					print("\t" .. key .. " = " .. tableToString(value, '') .. ",")
				end
			elseif type(value) == "string" then
				print("\t" .. key .. " = \"" .. value .. "\",")
			else
				print("\t" .. key .. " = " .. value .. ",")
			end
		end
		print("}\n")
	end
end
