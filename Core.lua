PetToolsData = {
  petActive = false,
  petGuid = nil,
  petType = nil,

  petExpirationTime = nil,
  petSummonDuration = nil,

  warlock = {
    powerOverwhelmingStartTime = nil,
    powerOverwhelmingDuration = nil,
    unleashedPotentialStartTime = nil,
    unleashedPotentialDuration = nil,
    unleashedPotentialStacks = 0,
  },

  settings = {
    enableUnleashedWarningSound = true,
    enablePetWarningSound = true,
    enableUPRefreshedSound = true,
    enableUPCritRefreshSound = true,
  },
}

local PetToolsEvents = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")

local PET_TYPE_BY_DISPLAY_ID = {
  [4449] = "imp",
  [1132] = "voidwalker",
  [4162] = "succubus",
  [850] = "felhunter",
  [7970] = "felguard",
  [1912] = "doomguard",
  [169] = "infernal",
}

PetToolsData.PET_SUMMON_DURATION_BY_TYPE = {
  imp = 0,
  succubus = 0,
  voidwalker = 0,
  felhunter = 0,
  felguard = 180,
  doomguard = 180,
  infernal = 180,
}

local UNLEASHED_POTENTIAL_SPELLS = {
  [51718] = true,
  [51719] = true,
  [51720] = true,
}

local HEALTH_FUNNEL_SPELLS = {
  [755] = true,
  [3698] = true,
  [3699] = true,
  [3700] = true,
  [11693] = true,
  [11694] = true,
  [11695] = true,
}

local POWER_OVERWHELMING = 51714

PetToolsData.SPELL_DURATIONS = {}
local SPELL_DURATION_IDS = { 51714, 51718, 51719, 51720 }

local REFRESH_FUNNEL_EVENT = "PetTools_RefreshFunnel"
local FUNNEL_RESET_SOUND_PATH = "Interface\\AddOns\\PetTools\\ding.mp3"
local CRIT_REFRESH_MIN_STACKS = 3
local SPELL_HIT_TYPE_CRIT = 2
local SETTINGS_DEFAULTS = {
  enableUnleashedWarningSound = true,
  enablePetWarningSound = true,
  enableUPRefreshedSound = true,
  enableUPCritRefreshSound = true,
}

local function InitializeSettings()
  PetToolsDB = PetToolsDB or {}
  PetToolsDB.settings = PetToolsDB.settings or {}

  for key, defaultValue in pairs(SETTINGS_DEFAULTS) do
    if PetToolsDB.settings[key] == nil then
      PetToolsDB.settings[key] = defaultValue
    end
    PetToolsData.settings[key] = PetToolsDB.settings[key]
  end
end

InitializeSettings()

local function NormalizeDurationSeconds(duration)
  if not duration or duration <= 0 then
    return nil
  end
  if duration > 100 then
    return duration / 1000
  end
  return duration
end

local function FindFirstDurationSeconds(ids)
  for _, spellId in ipairs(ids) do
    local duration = NormalizeDurationSeconds(PetToolsData.SPELL_DURATIONS[spellId])
    if duration then
      return duration
    end
  end
  return nil
end

PetToolsData.GetTimeRemaining = function(startTime, duration)
  if not startTime then
    return nil
  end

  local elapsed = GetTime() - startTime
  if duration and duration > 0 then
    return duration - elapsed
  end

  return nil
end

PetToolsData.fmtTimeRemaining = function(startTime, duration)
  if not startTime then
    return "nil"
  end

  local elapsed = GetTime() - startTime
  if duration and duration > 0 then
    return string.format("%.1fs elapsed / %.1fs left (of %.0fs)", elapsed, duration - elapsed, duration)
  end
  return string.format("%.1fs elapsed", elapsed)
end

local function RefreshFunnel()
  if PetToolsData.warlock.unleashedPotentialStacks > 0 then
    if PetToolsData.settings.enableUPRefreshedSound then
      PlaySoundFile(FUNNEL_RESET_SOUND_PATH)
    end
    PetToolsData.warlock.unleashedPotentialStartTime = GetTime()
  end
end

local function RefreshUnleashedOnCrit(hitInfo)
  if PetToolsData.warlock.unleashedPotentialStacks < CRIT_REFRESH_MIN_STACKS then
    return
  end

  if not UnitExists("pet") or UnitIsDead("pet") then
    return
  end

  local isCrit = bit.band(hitInfo or 0, SPELL_HIT_TYPE_CRIT) ~= 0
  if not isCrit then
    return
  end

  if PetToolsData.settings.enableUPCritRefreshSound then
    PlaySoundFile(FUNNEL_RESET_SOUND_PATH)
  end
  PetToolsData.warlock.unleashedPotentialStartTime = GetTime()
end

local function ClearPetData()
  PetToolsData.petActive = false
  PetToolsData.petGuid = nil
  PetToolsData.petType = nil
  PetToolsData.petExpirationTime = nil
  PetToolsData.petSummonDuration = nil
  PetToolsData.warlock.powerOverwhelmingStartTime = nil
  PetToolsData.warlock.unleashedPotentialStartTime = nil
  PetToolsData.warlock.unleashedPotentialStacks = 0
end

local function PetChanged()
  local petGuid = GetUnitGUID("pet")
  if not petGuid then
    ClearPetData()
    return
  end

  local displayId = GetUnitField("pet", "displayId")
  local petType = PET_TYPE_BY_DISPLAY_ID[displayId]
  PetToolsData.petActive = true
  PetToolsData.petGuid = petGuid
  PetToolsData.petType = petType
  local duration = PetToolsData.PET_SUMMON_DURATION_BY_TYPE[petType]
  PetToolsData.petSummonDuration = duration
  PetToolsData.petExpirationTime = duration and duration > 0 and (GetTime() + duration) or nil
  if PetToolsData.warlock.unleashedPotentialStacks <= 0 then
    PetToolsData.warlock.unleashedPotentialStartTime = nil
  end
end

local function SyncPetFromUnit()
  if not UnitExists("pet") then
    ClearPetData()
    return
  end

  PetChanged()
end

PetToolsEvents:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  for _, spellId in ipairs(SPELL_DURATION_IDS) do
    PetToolsData.SPELL_DURATIONS[spellId] = GetSpellDuration(spellId)
  end
  PetToolsData.warlock.powerOverwhelmingDuration = NormalizeDurationSeconds(PetToolsData.SPELL_DURATIONS[POWER_OVERWHELMING])
  PetToolsData.warlock.unleashedPotentialDuration = FindFirstDurationSeconds({ 51720, 51719, 51718 })
  SyncPetFromUnit()
end)

PetToolsEvents:RegisterEvent("UNIT_PET_GUID", function(guid, isPlayer, isTarget, isMouseover, isPet, partyIndex, raidIndex)
  -- 8-parameter event format:
  -- guid, isPlayer, isTarget, isMouseover, isPet, partyIndex, raidIndex
  if isPlayer ~= 1 or not guid then
    return
  end

  local petGuid = GetUnitGUID("pet")
  if PetToolsData.petGuid ~= petGuid then
    PetChanged()
  end
end)

PetToolsEvents:RegisterEvent("SPELL_GO_SELF", function(itemId, spellId)
  if spellId == POWER_OVERWHELMING then
    PetToolsData.warlock.powerOverwhelmingStartTime = GetTime()
  end
end)

PetToolsEvents:RegisterEvent("BUFF_REMOVED_SELF", function(guid, luaSlot, spellId)
  if spellId == POWER_OVERWHELMING then
    PetToolsData.warlock.powerOverwhelmingStartTime = nil
  end
end)

PetToolsEvents:RegisterEvent("BUFF_ADDED_OTHER", function(guid, luaSlot, spellId, stackCount, auraLevel, auraSlot)
  local petGuid = PetToolsData.petGuid
  if not petGuid or guid ~= petGuid then
    return
  end

  if not UNLEASHED_POTENTIAL_SPELLS[spellId] then
    return
  end

  PetToolsData.warlock.unleashedPotentialStartTime = GetTime()
  PetToolsData.warlock.unleashedPotentialStacks = stackCount or 1
end)

PetToolsEvents:RegisterEvent("BUFF_REMOVED_OTHER", function(guid, luaSlot, spellId, stackCount, auraLevel, auraSlot)
  local petGuid = PetToolsData.petGuid
  if not petGuid or guid ~= petGuid then
    return
  end

  local stacks = stackCount
  if UNLEASHED_POTENTIAL_SPELLS[spellId] then
    PetToolsData.warlock.unleashedPotentialStacks = stacks or 0
    if not stacks or stacks <= 0 then
      PetToolsData.warlock.unleashedPotentialStartTime = nil
    end
  end
end)

PetToolsEvents:RegisterEvent("SPELL_CAST_EVENT", function(success, spellId, castType, targetGuid, itemId)
  if success ~= 1 then
    return
  end
  if not HEALTH_FUNNEL_SPELLS[spellId] then
    return
  end
  if targetGuid ~= PetToolsData.petGuid then
    return
  end
  if PetToolsData.warlock.unleashedPotentialStacks <= 0 then
    return
  end

  PetToolsEvents:ScheduleEvent(REFRESH_FUNNEL_EVENT, RefreshFunnel, 1.1)
end)

PetToolsEvents:RegisterEvent("SPELL_FAILED_SELF", function(spellId, spellResult, failedByServer)
  if HEALTH_FUNNEL_SPELLS[spellId] then
    PetToolsEvents:CancelScheduledEvent(REFRESH_FUNNEL_EVENT)
  end
end)

PetToolsEvents:RegisterEvent("SPELL_DAMAGE_EVENT_SELF", function(targetGuid, casterGuid, spellId, amount, mitigationStr, hitInfo, spellSchool, effectAuraStr)
  RefreshUnleashedOnCrit(hitInfo)
end)

PetToolsEvents:RegisterEvent("UNIT_DIED", function(guid)
  if guid and guid == PetToolsData.petGuid then
    ClearPetData()
  end
end)

PetToolsEvents:RegisterEvent("PLAYER_DEAD", function()
  ClearPetData()
end)
