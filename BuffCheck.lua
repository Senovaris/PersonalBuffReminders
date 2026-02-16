local AURA_SCAN_LIMIT = 40
local isEating = false
local foodTimeRemaining = 0
local buffExpiryTimes = {}

local function CreateBuffOverlayFontString(frame, fontSize)
  local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetFont("Fonts\\FRIZQT__.TTF", fontSize or 20, "OUTLINE")
  fs:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
  fs:SetTextColor(1, 1, 1)
  fs:SetDrawLayer("OVERLAY", 7)
  return fs
end

local function ShowExpiryTimer(buffData, timeRemaining)
  if not buffData.expiryTimer then
    buffData.expiryTimer = CreateBuffOverlayFontString(buffData.frame, 20)
  end
  buffData.expiryTimer:SetText(math.floor(timeRemaining))
  buffData.expiryTimer:Show()
end

local function HideExpiryTimer(buffData)
  if buffData.expiryTimer then
    buffData.expiryTimer:Hide()
  end
end

local function CreateEatingTimer(buffData)
  if not buffData.eatingTimer then
    buffData.eatingTimer = CreateBuffOverlayFontString(buffData.frame, 20)
  end
end

local function HasWeaponEnchant()
  local hasMainHand, _, _, _, hasOffHand = GetWeaponEnchantInfo()
  return hasMainHand or hasOffHand
end

local function GetBuffTimeRemaining(buffName)
  local expiryTime = buffExpiryTimes[buffName]
  if not expiryTime then return 0 end
  return math.max(0, expiryTime - GetTime())
end

-- Aura names can be "secret" (tainted); string ops on them cause errors. Use pcall to skip those auras.
local function SafeAuraNameLower(auraData)
  if not auraData or not auraData.name then return nil end
  local ok, lowerName = pcall(string.lower, auraData.name)
  return ok and lowerName or nil
end

-- Scan only "player" auras (reliable). Returns map: buffName -> true, and updates buffExpiryTimes.
local function ScanPlayerAuras()
  local foundBuffs = {}
  buffExpiryTimes = {}

  if HasWeaponEnchant() then
    foundBuffs["Weapon Buffs"] = true
  end

  for i = 1, AURA_SCAN_LIMIT do
    local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not auraData then break end
    local lowerName = SafeAuraNameLower(auraData)
    if lowerName then
      for _, buffConfig in ipairs(buffsToTrack) do
        for _, searchTerm in ipairs(buffConfig.searchTerms) do
          if string.find(lowerName, searchTerm) then
            foundBuffs[buffConfig.name] = true
            if auraData.expirationTime then
              buffExpiryTimes[buffConfig.name] = auraData.expirationTime
            end
            break
          end
        end
      end
    end
  end

  return foundBuffs
end

-- Detect food/drink state from player auras (for eating timer).
local function UpdateFoodState()
  isEating = false
  foodTimeRemaining = 0
  for i = 1, AURA_SCAN_LIMIT do
    local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not auraData then break end
    local lowerName = SafeAuraNameLower(auraData)
    if lowerName then
      if string.find(lowerName, "food") or string.find(lowerName, "drink") then
        isEating = true
        if auraData.expirationTime then
          foodTimeRemaining = math.ceil(auraData.expirationTime - GetTime())
        end
        break
      end
    end
  end
end

local function ShouldHideForSpec(buffData)
  local buffConfig = buffData.config
  if not buffConfig.spec then return false end
  return GetSpecialization() ~= buffConfig.spec
end

-- Returns true if this buff's frame should be visible (used for dynamic layout order).
local function ShouldShowBuffFrame(buffName, buffData, foundBuffs)
  if buffName == "Food" then
    local hasWellFed = foundBuffs["Food"]
    local timeRemaining = GetBuffTimeRemaining("Food")
    return not hasWellFed or (hasWellFed and timeRemaining < 120)
  end
  if foundBuffs[buffName] then
    local timeRemaining = GetBuffTimeRemaining(buffName)
    local buffConfig = buffData.config
    return timeRemaining > 0 and timeRemaining < 120 and not buffConfig.noExpiryWarning
  end
  if buffName == "Rune" then
    return HasAugmentRuneInBags()
  end
  if buffName == "Healthstone" then
    -- Use class ID 9 (Warlock) so it works in all locales
    local _, _, playerClassID = UnitClass("player")
    local hasWarlock = (playerClassID == 9) or (GetAvailableClasses() and GetAvailableClasses()["WARLOCK"])
    return hasWarlock and not hasHealthStone()
  end
  return true
end

local function ApplyFoodFrameState(buffData, foundBuffs)
  local hasWellFed = foundBuffs["Food"]
  local timeRemaining = GetBuffTimeRemaining("Food")
  if not hasWellFed or (hasWellFed and timeRemaining < 120) then
    buffData.frame:Show()
    local showTimer = (isEating and foodTimeRemaining > 0) or (hasWellFed and timeRemaining < 120)
    if showTimer then
      CreateEatingTimer(buffData)
      local timerValue = foodTimeRemaining
      if hasWellFed and timeRemaining < 120 then
        timerValue = math.floor(timeRemaining)
      end
      buffData.eatingTimer:SetText(timerValue)
      buffData.eatingTimer:Show()
    else
      if buffData.eatingTimer then buffData.eatingTimer:Hide() end
    end
  else
    buffData.frame:Hide()
    if buffData.counterText then buffData.counterText:Hide() end
  end
end

local function ApplyTrackedBuffFrameState(buffData, buffName, foundBuffs)
  local buffConfig = buffData.config

  if foundBuffs[buffName] then
    local timeRemaining = GetBuffTimeRemaining(buffName)
    if timeRemaining > 0 and timeRemaining < 120 and not buffConfig.noExpiryWarning then
      buffData.frame:Show()
      ShowExpiryTimer(buffData, timeRemaining)
    else
      buffData.frame:Hide()
      HideExpiryTimer(buffData)
    end
  else
    if buffName == "Rune" then
      buffData.frame:SetShown(HasAugmentRuneInBags())
    elseif buffName == "Healthstone" then
      local _, _, playerClassID = UnitClass("player")
      local hasWarlock = (playerClassID == 9) or (GetAvailableClasses() and GetAvailableClasses()["WARLOCK"])
      buffData.frame:SetShown(hasWarlock and not hasHealthStone())
    else
      buffData.frame:Show()
    end
    HideExpiryTimer(buffData)
  end
end

function CheckBuffs()
  UpdateFoodState()
  local foundBuffs = ScanPlayerAuras()

  -- Dynamic layout: only visible buffs, packed with no gaps.
  local visibleBuffNames = {}
  for _, buffConfig in ipairs(buffsToTrack) do
    local buffName = buffConfig.name
    local buffData = buffFrames[buffName]
    if buffData and not ShouldHideForSpec(buffData) and ShouldShowBuffFrame(buffName, buffData, foundBuffs) then
      visibleBuffNames[#visibleBuffNames + 1] = buffName
    end
  end
  if LayoutVisibleBuffs then
    LayoutVisibleBuffs(visibleBuffNames)
  end

  -- Hide all first, then show only intended ones.
  for _, buffData in pairs(buffFrames) do
    if buffData.frame then
      buffData.frame:Hide()
    end
  end

  for buffName, buffData in pairs(buffFrames) do
    local buffConfig = buffData.config

    if ShouldHideForSpec(buffData) then
      buffData.frame:Hide()
    elseif buffName == "Food" then
      ApplyFoodFrameState(buffData, foundBuffs)
    else
      ApplyTrackedBuffFrameState(buffData, buffName, foundBuffs)
    end
  end
end
