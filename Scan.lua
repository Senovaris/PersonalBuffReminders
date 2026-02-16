-- Aura checks 

local AURA_SCAN_LIMIT = 40

function HasBuffOnUnit(unit, buffConfig)
  if not UnitExists(unit) or not UnitIsConnected(unit) then
    return true
  end

  if buffConfig.name == "Weapon Buffs" then
    if unit == "player" then
      local hasMainHand, _, _, _, hasOffHand = GetWeaponEnchantInfo()
      return hasMainHand or hasOffHand
    end
    return nil
  end

  -- Only scan player.
  if unit ~= "player" then
    return nil
  end

  for i = 1, AURA_SCAN_LIMIT do
    local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not auraData then
      break
    end
    if auraData.name then
      local lowerName = string.lower(auraData.name)
      for _, searchTerm in ipairs(buffConfig.searchTerms) do
        if string.find(lowerName, searchTerm) then
          return true
        end
      end
    end
  end
  return false
end
