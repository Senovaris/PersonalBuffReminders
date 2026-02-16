-- Functions for scanning bags/inventory

local augmentRuneIDs = {
  246492,
  224572,
  243191,
  259085,
  -- Add more as needed
}

function HasAugmentRuneInBags()
  for bagID = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    for slotID = 1, numSlots do
      local itemID = C_Container.GetContainerItemID(bagID, slotID)
      if itemID then
        for _, runeID in ipairs(augmentRuneIDs) do
          if itemID == runeID then
            return true
          end
        end
      end
    end
  end
  return false
end

-- Healthstone and Demonic Healthstone (and variants)
local healthStoneIDs = {
  5509,   -- Healthstone
  5512,   -- Minor Healthstone
  224464, -- Demonic Healthstone
}

function hasHealthStone()
  for bagID = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    for slotID = 1, numSlots do
      local itemID = C_Container.GetContainerItemID(bagID, slotID)
      if itemID then
        for _, hsID in ipairs(healthStoneIDs) do
          if itemID == hsID then
            return true
          end
        end
      end
    end
  end
  return false
end
