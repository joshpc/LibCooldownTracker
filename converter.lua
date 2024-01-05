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

function tableToString(t, indent)
    local str = "{ "
    for key, value in pairs(t) do
        if type(value) == "table" then
            str = str .. "[" .. key .. "] = " .. tableToString(value) .. ", "
        else
            str = str .. "[" .. key .. "] = " .. tostring(value) .. ", "
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

function getSortedKeys(t)
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

for className, spells in pairs(E.spell_db) do
	keys = getSortedKeys(spells)
	print("============ " .. className .. " ============")
    for _, spellKey in pairs(keys) do
		spell = spells[spellKey]

		print("LCT_SpellData[" .. spell["spellID"] .. "] = {")
		for key, value in pairs(spell) do
			uniqueKeys[key] = true

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
				print("\t" .. key .. " = " .. tableToString(value, '') .. ",")
			elseif type(value) == "string" then
				print("\t" .. key .. " = \"" .. value .. "\",")
			else
				print("\t" .. key .. " = " .. value .. ",")
			end
		end
		print("}\n")
	end
end
