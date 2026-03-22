local L = AceLibrary("AceLocale-2.2"):new("PetTools")

local PetToolsOptions = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "FuBarPlugin-2.0", "AceConsole-2.0")
PetToolsOptions.name = L["FuBar - PetTools"]
PetToolsOptions:RegisterDB("PetToolsDB")
PetToolsOptions.hasIcon = "Interface\\Icons\\Ability_Warlock_DemonicPower"
PetToolsOptions.defaultMinimapPosition = 180
PetToolsOptions.independentProfile = true
PetToolsOptions.hideWithoutStandby = false

local SETTINGS_DEFAULTS = {
  enableUnleashedWarningSound = true,
  enablePetWarningSound = true,
  enableUPRefreshedSound = true,
}

local function EnsureSettings()
  PetToolsDB = PetToolsDB or {}
  PetToolsDB.settings = PetToolsDB.settings or {}
  PetToolsData.settings = PetToolsData.settings or {}

  for key, defaultValue in pairs(SETTINGS_DEFAULTS) do
    if PetToolsDB.settings[key] == nil then
      PetToolsDB.settings[key] = defaultValue
    end
    if PetToolsData.settings[key] == nil then
      PetToolsData.settings[key] = PetToolsDB.settings[key]
    end
  end
end

local function GetSetting(key)
  EnsureSettings()
  local value = PetToolsData.settings[key]
  if value == nil then
    return SETTINGS_DEFAULTS[key]
  end
  return value
end

local function SetSetting(key, value)
  EnsureSettings()
  PetToolsData.settings[key] = value and true or false
  PetToolsDB.settings[key] = value and true or false
end

local function ResetIconPosition()
  if PetToolsData and PetToolsData.ResetIconPosition then
    PetToolsData.ResetIconPosition()
  end
end

local options = {
  type = "group",
  name = L["PetTools"],
  desc = L["PetTools options"],
  args = {
    resetIconPosition = {
      type = "execute",
      name = L["Reset Icon Position"],
      desc = L["Move icons back near the lower-left of screen"],
      order = 1,
      func = ResetIconPosition,
    },
    enableUnleashedWarningSound = {
      type = "toggle",
      name = L["Unleashed Potential Expiring Sound"],
      desc = L["Play sound when Unleashed Potential is about to expire"],
      order = 2,
      get = function()
        return GetSetting("enableUnleashedWarningSound")
      end,
      set = function(v)
        SetSetting("enableUnleashedWarningSound", v)
      end,
    },
    enablePetWarningSound = {
      type = "toggle",
      name = L["Pet Expiring Sound"],
      desc = L["Play sound when pet summon time is about to expire"],
      order = 3,
      get = function()
        return GetSetting("enablePetWarningSound")
      end,
      set = function(v)
        SetSetting("enablePetWarningSound", v)
      end,
    },
    enableUPRefreshedSound = {
      type = "toggle",
      name = L["Unleashed Potential Health Funnel Refresh Sound"],
      desc = L["Play sound when Health Funnel refreshes the Unleashed Potential timer"],
      order = 4,
      get = function()
        return GetSetting("enableUPRefreshedSound")
      end,
      set = function(v)
        SetSetting("enableUPRefreshedSound", v)
      end,
    },
  },
}

EnsureSettings()
PetToolsOptions.OnMenuRequest = options
local fubarOptions = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(PetToolsOptions)
if fubarOptions and fubarOptions.args then
  for k, v in pairs(fubarOptions.args) do
    if PetToolsOptions.OnMenuRequest.args[k] == nil then
      PetToolsOptions.OnMenuRequest.args[k] = v
    end
  end
end
PetToolsOptions:RegisterChatCommand({ "/pettools" }, options)
