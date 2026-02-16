local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("BAG_UPDATE")

local function IsSafeToUpdate()
  return not InCombatLockdown()
end

local function RunBuffUpdate()
  CheckBuffs()
  UpdateCounters()
end

local function UpdateFrameMouseState()
  if not buffFrames then return end
end

local function RefreshBuffUI()
  BuildBuffFrames()
  UpdateFrameMouseState()
  RunBuffUpdate()
end

local function EnsureLayoutStorage(layoutName)
  if not AursBRDB.layouts then
    AursBRDB.layouts = {}
  end
  if not AursBRDB.layouts[layoutName] then
    AursBRDB.layouts[layoutName] = { point = "CENTER", x = 0, y = 0 }
  end
end

eventFrame:SetScript("OnEvent", function(_, event, unit)
  if not AursBRDB.buffRemindersEnabled then return end

  if event == "PLAYER_ENTERING_WORLD" then
    if IsSafeToUpdate() then
      RefreshBuffUI()
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if BuffRemindersContainer then
      BuffRemindersContainer:Hide()
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if BuffRemindersContainer then
      BuffRemindersContainer:Show()
    end
    RefreshBuffUI()
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    RunBuffUpdate()
  elseif event == "UNIT_AURA" then
    if unit == "player" then
      RunBuffUpdate()
    end
  elseif event == "BAG_UPDATE" then
    RunBuffUpdate()
  elseif event == "PLAYER_LOGIN" then
    local LEM = LibStub('LibEditMode', true)
    if LEM and BuffRemindersContainer then
      local function onPositionChanged(_, layoutName, point, x, y)
        EnsureLayoutStorage(layoutName)
        AursBRDB.layouts[layoutName].point = point
        AursBRDB.layouts[layoutName].x = x
        AursBRDB.layouts[layoutName].y = y
      end

      local defaultPosition = { point = 'CENTER', x = 0, y = 0 }

      LEM:RegisterCallback('layout', function(layoutName)
        EnsureLayoutStorage(layoutName)
        local layout = AursBRDB.layouts[layoutName]
        BuffRemindersContainer:ClearAllPoints()
        BuffRemindersContainer:SetPoint(
          layout.point or "CENTER",
          UIParent,
          layout.point or "CENTER",
          layout.x or 0,
          layout.y or 0)
        end)
        LEM:AddFrame(BuffRemindersContainer, onPositionChanged, defaultPosition, 'Buff Reminders')
      end
    end
  end)
