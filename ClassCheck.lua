function GetAvailableClasses()
	local availableClasses = {}
	local _, playerClass = UnitClass("player")
	availableClasses[playerClass] = true

	if IsInRaid() then
		for i = 1, 40 do
			local unit = "raid" .. i
			if UnitExists(unit) then
				local _, classFilename = UnitClass(unit)
				if classFilename then
					availableClasses[classFilename] = true
				end
			end
		end
	elseif IsInGroup() then
		for i = 1, 4 do
			local unit = "party" .. i
			if UnitExists(unit) then
				local _, classFilename = UnitClass(unit)
				if classFilename then
					availableClasses[classFilename] = true
				end
			end
		end
	end
	return availableClasses
end
function ShouldShowBuff(buffConfig)
	if #buffConfig.classes == 0 then
		return true
	end
	if buffConfig.selfOnly then
		local _, playerClass = UnitClass("player")
		for _, requiredClass in ipairs(buffConfig.classes) do
			if playerClass == requiredClass then
				return true
			end
		end
		return false
	end

	local availableClasses = GetAvailableClasses()
	for _, requiredClass in ipairs(buffConfig.classes) do
		if availableClasses[requiredClass] then
			return true
		end
	end
	return false
end
