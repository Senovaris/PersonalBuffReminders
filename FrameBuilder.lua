local ICON_SIZE = 64
local ICON_GAP = 2
local MIN_SIZE = 50

local function GetLayoutSize(count)
  local w = count > 0 and ((count * ICON_SIZE) + ((count - 1) * ICON_GAP)) or MIN_SIZE
  local h = count > 0 and ICON_SIZE or MIN_SIZE
  return w, h
end

local function SetFrameLayoutPosition(frame, index)
  local xOffset = (index - 1) * (ICON_SIZE + ICON_GAP)
  frame:SetSize(ICON_SIZE, ICON_SIZE)
  frame:ClearAllPoints()
  frame:SetPoint("LEFT", BuffRemindersContainer, "LEFT", xOffset, 0)
end

function BuildBuffFrames()
  if buffFrames then
    for buffName, buffData in pairs(buffFrames) do
      if buffData.frame then
        buffData.frame:Hide()
        buffData.frame:SetParent(nil)
      end
    end
  end

  if not BuffRemindersContainer then
    BuffRemindersContainer = CreateFrame("Frame", "BuffRemindersContainer", UIParent)
  end

  buffFrames = {}
  local totalBuffs = 0
  for _, buffConfig in ipairs(buffsToTrack) do
    if ShouldShowBuff(buffConfig) then
      totalBuffs = totalBuffs + 1
    end
  end

  local totalWidth, totalHeight = GetLayoutSize(totalBuffs)
  BuffRemindersContainer:SetSize(totalWidth, totalHeight)

  local currentSlot = 0
  for _, buffConfig in ipairs(buffsToTrack) do
    if ShouldShowBuff(buffConfig) then
      currentSlot = currentSlot + 1
      local frame = CreateFrame("Frame", buffConfig.name .. "ReminderFrame", BuffRemindersContainer)
      SetFrameLayoutPosition(frame, currentSlot)
      local icon = frame:CreateTexture(nil, "ARTWORK")
      icon:SetAllPoints(frame)
      icon:SetTexture(buffConfig.icon)
      buffFrames[buffConfig.name] = {
        frame = frame,
        config = buffConfig,
        slot = currentSlot - 1,
      }
    end
  end
end

function LayoutVisibleBuffs(visibleBuffNames)
  if not BuffRemindersContainer or not buffFrames then return end
  local count = #visibleBuffNames
  local totalWidth, totalHeight = GetLayoutSize(count)
  -- Keep the left edge fixed when resizing so the container doesn't shift toward center
  local left, bottom = BuffRemindersContainer:GetLeft(), BuffRemindersContainer:GetBottom()
  BuffRemindersContainer:SetSize(totalWidth, totalHeight)
  if left and bottom then
    BuffRemindersContainer:ClearAllPoints()
    BuffRemindersContainer:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
  end
  for i, buffName in ipairs(visibleBuffNames) do
    local buffData = buffFrames[buffName]
    if buffData and buffData.frame then
      SetFrameLayoutPosition(buffData.frame, i)
    end
  end
end

