local function fmt(v)
  if v == nil then return "nil" end
  if type(v) == "boolean" then return tostring(v) end
  if type(v) == "number" then return string.format("%.3f", v) end
  return tostring(v)
end

local poDuration = nil
local upDuration = nil

local function cacheDurations()
  if not poDuration then
    local d = GetSpellDuration(51714)
    if d then poDuration = d / 1000 end
  end
  if not upDuration then
    for _, id in ipairs({ 51720, 51719, 51718 }) do
      local d = GetSpellDuration(id)
      if d and d > 0 then
        upDuration = d / 1000
        break
      end
    end
  end
end

local function fmtTimeRemaining(startTime, duration)
  if not startTime then return "nil" end
  local elapsed = GetTime() - startTime
  if duration and duration > 0 then
    return string.format("%.1fs elapsed / %.1fs left (of %.0fs)", elapsed, duration - elapsed, duration)
  end
  return string.format("%.1fs elapsed", elapsed)
end

local function fmtExpiry(expiryTime)
  if not expiryTime then return "nil" end
  local remaining = expiryTime - GetTime()
  return string.format("%.3f (%.1fs left)", expiryTime, remaining)
end

local debugFrame = CreateFrame("Frame", "PetToolsDebugFrame", UIParent)
debugFrame:SetWidth(320)
debugFrame:SetHeight(220)
debugFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
debugFrame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
debugFrame:SetBackdropColor(0, 0, 0, 0.85)
debugFrame:SetFrameStrata("HIGH")
debugFrame:EnableMouse(true)
debugFrame:SetMovable(true)
debugFrame:RegisterForDrag("LeftButton")
debugFrame:SetScript("OnDragStart", function() this:StartMoving() end)
debugFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local title = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -14)
title:SetText("|cffffff00PetToolsData|r")

local body = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
body:SetPoint("TOPLEFT", debugFrame, "TOPLEFT", 16, -30)
body:SetPoint("BOTTOMRIGHT", debugFrame, "BOTTOMRIGHT", -16, 14)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")
body:SetNonSpaceWrap(true)

local elapsed = 0
debugFrame:SetScript("OnUpdate", function()
  elapsed = elapsed + arg1
  if elapsed < 1 then return end
  elapsed = 0

  cacheDurations()

  local d = PetToolsData
  local w = d.warlock

  local lines = {
    "petActive:  " .. fmt(d.petActive),
    "petGuid:    " .. fmt(d.petGuid),
    "petType:    " .. fmt(d.petType),
    "petSummonDuration: " .. fmt(d.petSummonDuration),
    "petExpirationTime: " .. fmtExpiry(d.petExpirationTime),
    "",
    "|cffffff00warlock:|r",
    "  PO:  " .. fmtTimeRemaining(w.powerOverwhelmingStartTime, poDuration),
    "  UP:  " .. fmtTimeRemaining(w.unleashedPotentialStartTime, upDuration),
    "  upStacks: " .. fmt(w.unleashedPotentialStacks),
  }

  body:SetText(table.concat(lines, "\n"))
end)
