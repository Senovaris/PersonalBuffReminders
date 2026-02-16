function UpdateCounters()
  if not buffFrames then return end
  for _, buffData in pairs(buffFrames) do
    if buffData.counterText then
      buffData.counterText:Hide()
    end
  end
end
