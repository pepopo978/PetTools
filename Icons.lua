local _, class = UnitClass("player")
if class ~= "WARLOCK" then
  return
end

local unleashedFrame = CreateFrame("Frame", "PetToolsUnleashedFrame", UIParent)
unleashedFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
unleashedFrame:SetWidth(40)
unleashedFrame:SetHeight(40)
unleashedFrame:SetFrameStrata("HIGH")
unleashedFrame:Show()
unleashedFrame:EnableMouse(true)
unleashedFrame:EnableMouseWheel(true)
unleashedFrame:SetMovable(true)
unleashedFrame:RegisterForDrag("LeftButton")
unleashedFrame:SetScript("OnDragStart", function()
  unleashedFrame:StartMoving()
end)
unleashedFrame:SetScript("OnDragStop", function()
  unleashedFrame:StopMovingOrSizing()
end)

local unleashedIcon = unleashedFrame:CreateTexture(nil, "OVERLAY")
unleashedIcon:SetAllPoints(unleashedFrame)
unleashedIcon:SetTexture("Interface\\Icons\\Ability_Warlock_DemonicPower")
unleashedIcon:SetDesaturated(true)

local unleashedStackText = unleashedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
unleashedStackText:SetPoint("BOTTOM", unleashedFrame, "TOP", 0, 4)
unleashedStackText:SetFont("Fonts\\FRIZQT__.TTF", 18, "THICKOUTLINE")
unleashedStackText:SetTextColor(0.8, 0.9, 1)
unleashedStackText:SetText("")

local unleashedTimerText = unleashedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
unleashedTimerText:SetPoint("CENTER", unleashedFrame, "CENTER", 0, 0)
unleashedTimerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "THICKOUTLINE")
unleashedTimerText:SetTextColor(1, 1, 1)
unleashedTimerText:SetText("")

local powerFrame = CreateFrame("Frame", "PetToolsPowerOverwhelmingFrame", UIParent)
powerFrame:SetPoint("RIGHT", unleashedFrame, "LEFT", -6, 0)
powerFrame:SetWidth(40)
powerFrame:SetHeight(40)
powerFrame:SetFrameStrata("HIGH")
powerFrame:Show()
powerFrame:EnableMouse(true)
powerFrame:EnableMouseWheel(true)

local powerIcon = powerFrame:CreateTexture(nil, "OVERLAY")
powerIcon:SetAllPoints(powerFrame)
powerIcon:SetTexture("Interface\\Icons\\Ability_Warlock_Power_Overwhelming")
powerIcon:SetDesaturated(true)

local powerTimerText = powerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
powerTimerText:SetPoint("CENTER", powerFrame, "CENTER", 0, 0)
powerTimerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "THICKOUTLINE")
powerTimerText:SetTextColor(1, 1, 1)
powerTimerText:SetText("")

local petFrame = CreateFrame("Frame", "PetToolsPetSummonFrame", UIParent)
petFrame:SetPoint("LEFT", unleashedFrame, "RIGHT", 6, 0)
petFrame:SetWidth(40)
petFrame:SetHeight(40)
petFrame:SetFrameStrata("HIGH")
petFrame:Show()

local petIcon = petFrame:CreateTexture(nil, "OVERLAY")
petIcon:SetAllPoints(petFrame)
petIcon:SetTexture("Interface\\Icons\\Spell_Shadow_SummonImp")
petIcon:SetDesaturated(true)

local petTimerText = petFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
petTimerText:SetPoint("CENTER", petFrame, "CENTER", 0, 0)
petTimerText:SetFont("Fonts\\FRIZQT__.TTF", 13, "THICKOUTLINE")
petTimerText:SetTextColor(1, 1, 1)
petTimerText:SetText("")

local function ResizeIconGroup(self, delta)
  if IsShiftKeyDown() then
    local wheelDelta = delta or arg1 or 0
    local size = unleashedFrame:GetWidth()
    local newSize = math.max(20, math.min(200, size + wheelDelta * 5))
    local scale = newSize / 40
    local fontSize = math.floor(16 * scale)

    unleashedFrame:SetWidth(newSize)
    unleashedFrame:SetHeight(newSize)
    powerFrame:SetWidth(newSize)
    powerFrame:SetHeight(newSize)
    petFrame:SetWidth(newSize)
    petFrame:SetHeight(newSize)

    unleashedStackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize + 2, "THICKOUTLINE")
    unleashedTimerText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "THICKOUTLINE")
    powerTimerText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "THICKOUTLINE")
    petTimerText:SetFont("Fonts\\FRIZQT__.TTF", math.max(8, fontSize - 3), "THICKOUTLINE")
  end
end

unleashedFrame:SetScript("OnMouseWheel", ResizeIconGroup)
powerFrame:SetScript("OnMouseWheel", ResizeIconGroup)

local WARNING_THRESHOLD = 5
local WARNING_SOUND_PATH = "Interface\\AddOns\\PetTools\\Pet.mp3"
local petExpiryWarned = false
local unleashedExpiryWarned = false
local PET_ICON_TEXTURE_BY_TYPE = {
  felguard = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
  infernal = "Interface\\Icons\\Spell_Shadow_SummonInfernal",
  doomguard = "Interface\\Icons\\Spell_Shadow_AntiMagicShell",
}
local DEFAULT_PET_ICON_TEXTURE = "Interface\\Icons\\Spell_Shadow_SummonImp"
local currentPetIconTexture = DEFAULT_PET_ICON_TEXTURE

local function UpdateIcons()
  local warlockState = PetToolsData and PetToolsData.warlock
  local petType = PetToolsData and PetToolsData.petType
  local petTexture = PET_ICON_TEXTURE_BY_TYPE[petType]
  local isSupportedPetType = petTexture ~= nil

  if isSupportedPetType and currentPetIconTexture ~= petTexture then
    petIcon:SetTexture(petTexture)
    currentPetIconTexture = petTexture
  elseif not isSupportedPetType and currentPetIconTexture ~= DEFAULT_PET_ICON_TEXTURE then
    petIcon:SetTexture(DEFAULT_PET_ICON_TEXTURE)
    currentPetIconTexture = DEFAULT_PET_ICON_TEXTURE
  end

  if not warlockState then
    unleashedIcon:SetDesaturated(true)
    unleashedStackText:Hide()
    unleashedStackText:SetText("")
    unleashedTimerText:SetText("")
    powerIcon:SetDesaturated(true)
    powerTimerText:SetText("")
    petFrame:Hide()
    petExpiryWarned = false
    unleashedExpiryWarned = false
    return
  end

  local unleashedStacks = warlockState.unleashedPotentialStacks or 0
  local unleashedStartTime = warlockState.unleashedPotentialStartTime
  local petAlive = UnitExists("pet") and not UnitIsDead("pet")
  local hasUnleashed = unleashedStacks > 0 and petAlive
  local shouldPlayPetWarning = false
  local shouldPlayUnleashedWarning = false

  local hasPetTimer = false
  local petRemaining = nil
  if isSupportedPetType and PetToolsData.petExpirationTime then
    petRemaining = PetToolsData.petExpirationTime - GetTime()
    if petRemaining and petRemaining > 0 then
      hasPetTimer = true
      if petRemaining > WARNING_THRESHOLD then
        petExpiryWarned = false
      elseif not petExpiryWarned then
        shouldPlayPetWarning = true
        petExpiryWarned = true
      end
    else
      petExpiryWarned = false
    end
  else
    petExpiryWarned = false
  end

  local hasUnleashedTimer = false
  local unleashedRemaining = nil
  if hasUnleashed and unleashedStartTime then
    local unleashedDuration = warlockState.unleashedPotentialDuration
    local getRemaining = PetToolsData.GetTimeRemaining
    unleashedRemaining = getRemaining and getRemaining(unleashedStartTime, unleashedDuration)
    if unleashedRemaining and unleashedRemaining > 0 then
      hasUnleashedTimer = true
      if unleashedRemaining > WARNING_THRESHOLD then
        unleashedExpiryWarned = false
      elseif not unleashedExpiryWarned then
        shouldPlayUnleashedWarning = true
        unleashedExpiryWarned = true
      end
    else
      unleashedExpiryWarned = false
    end
  else
    unleashedExpiryWarned = false
  end

  if hasUnleashedTimer then
    unleashedTimerText:SetText(string.format("%.1f", unleashedRemaining))
  else
    unleashedTimerText:SetText("")
  end

  local hasPowerTimer = false
  local powerRemaining = nil
  if warlockState.powerOverwhelmingStartTime then
    local getRemaining = PetToolsData.GetTimeRemaining
    powerRemaining = getRemaining and getRemaining(warlockState.powerOverwhelmingStartTime, warlockState.powerOverwhelmingDuration)
    if powerRemaining and powerRemaining > 0 then
      hasPowerTimer = true
    end
  end

  if hasPowerTimer then
    powerIcon:SetDesaturated(false)
    powerTimerText:SetText(string.format("%.1f", powerRemaining))
  else
    powerIcon:SetDesaturated(true)
    powerTimerText:SetText("")
  end

  if hasPetTimer then
    petFrame:Show()
    petIcon:SetDesaturated(false)
    petTimerText:SetText(string.format("%d", math.max(0, math.ceil(petRemaining))))
  elseif isSupportedPetType then
    petFrame:Show()
    petIcon:SetDesaturated(true)
    petTimerText:SetText("")
  else
    petFrame:Hide()
    petTimerText:SetText("")
  end

  if not hasUnleashed then
    unleashedIcon:SetDesaturated(true)
    unleashedStackText:Hide()
    unleashedStackText:SetText("")
  else
    unleashedIcon:SetDesaturated(false)
    unleashedStackText:Show()
    if warlockState.powerOverwhelmingStartTime then
      unleashedStackText:SetTextColor(1, 0.8, 0.2)
    else
      unleashedStackText:SetTextColor(0.8, 0.9, 1)
    end
    unleashedStackText:SetText(unleashedStacks)
  end

  local settings = PetToolsData and PetToolsData.settings
  local allowPetWarningSound = not settings or settings.enablePetWarningSound ~= false
  local allowUnleashedWarningSound = not settings or settings.enableUnleashedWarningSound ~= false
  if (shouldPlayPetWarning and allowPetWarningSound) or (shouldPlayUnleashedWarning and allowUnleashedWarningSound) then
    PlaySoundFile(WARNING_SOUND_PATH)
  end
end

unleashedFrame:SetScript("OnUpdate", function()
  if (this.throttleTick or 0) > GetTime() then
    return
  end
  this.throttleTick = GetTime() + 0.1

  UpdateIcons()
end)

PetToolsData.ResetIconPosition = function()
  unleashedFrame:ClearAllPoints()
  unleashedFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 100, 100)
end

PetToolsData.unleashedFrame = unleashedFrame
PetToolsData.unleashedFrame.icon = unleashedIcon
PetToolsData.unleashedFrame.stackText = unleashedStackText
PetToolsData.unleashedFrame.timerText = unleashedTimerText
PetToolsData.powerOverwhelmingFrame = powerFrame
PetToolsData.powerOverwhelmingFrame.icon = powerIcon
PetToolsData.powerOverwhelmingFrame.timerText = powerTimerText
PetToolsData.petFrame = petFrame
PetToolsData.petFrame.icon = petIcon
PetToolsData.petFrame.timerText = petTimerText
