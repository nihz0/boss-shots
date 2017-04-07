-- Nihz's Boss Shots
-- A World of Warcraft Addon that automatically take annotated screenshots of all 
-- your boss kills.
-- Written by Nihz of US-Stormrage (nihz.stormrage@gmail.com)

-- Addon creation boilerplate stuff.
local ADDON_NAME = "BossShots"
local ADDON_DB_NAME = ADDON_NAME .. "DB"
local ADDON_DISPLAY_NAME = "Boss Shots"
BossShots = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0") 

-- Instance type and difficulty map.  This maps the game's different difficulties to the 
-- simplified version used in this addon.  Things mapped to none will ignore
-- the settings filters.
local INSTANCE_NONE = 0
local INSTANCE_NORMAL_DUNGEON = 1
local INSTANCE_HEROIC_DUNGEON = 2
local INSTANCE_MYTHIC_DUNGEON = 3
local INSTANCE_LFR_RAID = 4
local INSTANCE_NORMAL_RAID = 5
local INSTANCE_HEROIC_RAID = 6
local INSTANCE_MYTHIC_RAID = 7
local INSTANCE_TIMEWALKING_DUNGEON = 8
local INSTANCE_DIFFICULTY_MAP = {
  INSTANCE_NONE, -- 0 - None; not in an Instance.
  INSTANCE_NORMAL_DUNGEON, -- 1 - 5-player Instance.
  INSTANCE_HEROIC_DUNGEON, -- 2 - 5-player Heroic Instance.
  INSTANCE_NORMAL_RAID, -- 3 - 10-player Raid Instance.
  INSTANCE_NORMAL_RAID, -- 4 - 25-player Raid Instance.
  INSTANCE_HEROIC_RAID, -- 5 - 10-player Heroic Raid Instance.
  INSTANCE_HEROIC_RAID, -- 6 - 25-player Heroic Raid Instance.
  INSTANCE_RAIDFINDER_RAID, -- 7 - 25-player Raid Finder Instance.
  INSTANCE_NONE, -- 8 - Challenge Mode Instance.
  INSTANCE_NORMAL_RAID, -- 9 - 40-player Raid Instance.
  INSTANCE_NONE, -- 10 - Not used.
  INSTANCE_NONE, -- 11 - Heroic Scenario Instance.
  INSTANCE_NONE, -- 12 - Scenario Instance.
  INSTANCE_NONE, -- 13 - Not used.
  INSTANCE_NORMAL_RAID, -- 14 - 10-30-player Normal Raid Instance.
  INSTANCE_HEROIC_RAID, -- 15 - 10-30-player Heroic Raid Instance.
  INSTANCE_MYTHIC_RAID, -- 16 - 20-player Mythic Raid Instance .
  INSTANCE_RAIDFINDER_RAID, -- 17 - 10-30-player Raid Finder Instance.
  INSTANCE_NORMAL_RAID, -- 18 - 40-player Event raid (Used by the level 100 version of Molten Core for WoW's 10th anniversary).
  INSTANCE_NORMAL_RAID, -- 19 - 5-player Event instance (Used by the level 90 version of UBRS at WoD launch).
  INSTANCE_NONE, -- 20 - 25-player Event scenario (unknown usage).
  INSTANCE_NONE, -- 21 - Not used.
  INSTANCE_NONE, -- 22 - Not used.
  INSTANCE_MYTHIC_DUNGEON, -- 23 - Mythic 5-player Instance.
  INSTANCE_TIMEWALKING_DUNGEON -- 24 - Timewalker 5-player Instance.
}

-- Declare and implement configuration options.
local db
local configOptions = {
  name = ADDON_DISPLAY_NAME,
  handler = BossShots,
  type = "group",
  args = {
    enabled = {
      type = "toggle",
      name = "Enable Boss Shots",
      desc = "Automatically take screenshots of your boss kills.",
      get = function() return db.profile.enabled end,
      set = function(_, value) 
        db.profile.enabled = value
        if value then 
          BossShots:Enable()
        else
          BossShots:Disable()
        end 
      end
    },
    settings = {
      order = 1,
      type = "group",
      name = "Settings",
      desc = "Managed when and how screenshots are taken.",
      args = {
        enableWhenSoloing = {
          order = 1,
          type = "toggle",
          name = "Enable when soloing",
          desc = "Controls whether a screenshot will be taken when defeating a boss without being in a group (i.e. soloing old dungeons and raids.)",
          get = function() return db.profile.enableWhenSoloing end,
          set = function(_, value) db.profile.enableWhenSoloing = value end
        },
        enableWhenOutdoors = {
          order = 2,
          type = "toggle",
          name = "Enable when outdoors",
          desc = "Controls whether a screenshot will be taken when defeating a world boss.",
          get = function() return db.profile.enableWhenOutdoors end,
          set = function(_, value) db.profile.enableWhenOutdoors = value end
        },
        enableOnWipes = {
          order = 3,
          type = "toggle",
          name = "Enable on wipes",
          desc = "Controls whether a screenshot will be taken when a wipe occurs.",
          get = function() return db.profile.enableOnWipes end,
          set = function(_, value) db.profile.enableOnWipes = value end
        },
        dungeonSettings = {
          order = 10,
          type = "group",
          inline = true,
          name = "Dungeon Settings",
          desc = "Controls when screenshots are taken in dungeons based on difficulty level.",
          args = {
            enableNormal = {
              order = 1,
              type = "toggle",
              name = "Normal",
              desc = "Enable in normal difficulty dungeons.",
              get = function() return db.profile.enableInNormalDungeons end,
              set = function(_, value) db.profile.enableInNormalDungeons = value end
            },
            enableHeroic = {
              order = 2,
              type = "toggle",
              name = "Heroic",
              desc = "Enable in heroic difficulty dungeons.",
              get = function() return db.profile.enableInHeroicDungeons end,
              set = function(_, value) db.profile.enableInHeroicDungeons = value end
            },
            enableMythic = {
              order = 3,
              type = "toggle",
              name = "Mythic",
              desc = "Enable in mythic difficulty dungeons.",
              get = function() return db.profile.enableInMythicDungeons end,
              set = function(_, value) db.profile.enableInMythicDungeons = value end
            },
            enableTimewalking = {
              order = 4,
              type = "toggle",
              name = "Timewalking",
              desc = "Enable in time walking difficulty dungeons.",
              get = function() return db.profile.enableInTimewalkingDungeons end,
              set = function(_, value) db.profile.enableInTimewalkingDungeons = value end
            }
          }
        },
        raidSettings = {
          order = 20,
          type = "group",
          inline = true,
          name = "Raid Settings",
          desc = "Controls when screenshots are taken in raids based on difficulty level.",
          args = {
            enableRaidFinder = {
              order = 1,
              type = "toggle",
              name = "Raid Finder",
              desc = "Enable in raid finder (LFR) difficulty \"raids\".",
              get = function() return db.profile.enableInRaidFinderRaids end,
              set = function(_, value) db.profile.enableInRaidFinderRaids = value end
            },
            enableNormal = {
              order = 2,
              type = "toggle",
              name = "Normal",
              desc = "Enable in normal difficulty raids.",
              get = function() return db.profile.enableInNormalRaids end,
              set = function(_, value) db.profile.enableInNormalRaids = value end
            },
            enableHeroic = {
              order = 3,
              type = "toggle",
              name = "Heroic",
              desc = "Enable in heroic difficulty raids.",
              get = function() return db.profile.enableInHeroicRaids end,
              set = function(_, value) db.profile.enableInHeroicRaids = value end
            },
            enableMythic = {
              order = 4,
              type = "toggle",
              name = "Mythic",
              desc = "Enable in mythic difficulty raids.",
              get = function() return db.profile.enableInMythicRaids end,
              set = function(_, value) db.profile.enableInMythicRaids = value end
            }
          }
        }
      }
    }
  }
}

-- Setup default configuration values. 
local defaults = {
	profile = {
		enabled = true,
    enableWhenSoloing = false,
    enableWhenOutdoors = true,
    enableOnWipes = false,
    enableInNormalDungeons = true,
    enableInHeroicDungeons = true,
    enableInMythicDungeons = true,
    enableInNormalRaids = true,
    enableInHeroicRaids = true,
    enableInMythicRaids = true
	}
}

-- Code that you want to run when the addon is first loaded goes here.
function BossShots:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New(ADDON_DB_NAME, defaults)
  db = self.db
  configOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, configOptions, {"bossshots"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_DISPLAY_NAME)
  self:Print("|cFF99CC33Nihz's " .. ADDON_DISPLAY_NAME .. "|r initialized.")
end

-- Called when the addon is enabled
function BossShots:OnEnable()
  if not db.profile.enabled then
    self:Disable()
    return
  end
  self:RegisterEvent("ENCOUNTER_START")
  self:RegisterEvent("ENCOUNTER_END")
  self:Print("|cFF99CC33Nihz's " .. ADDON_DISPLAY_NAME .. "|r enabled.")
end

-- Called when the addon is disabled
function BossShots:OnDisable()
  self:Print("|cFF99CC33Nihz's " .. ADDON_DISPLAY_NAME .. "|r disabled.")
end

-- Responds to an encounter starting by capturing the start time.
function BossShots:ENCOUNTER_START()
  self.encounterStartTime = time()
end

-- Responds to am encounter ending.  If the encounter was successful (i.e. not 
-- a wipe), schedules a timer to a take a delayed screenshot.
function BossShots:ENCOUNTER_END(event, encounterId, encounterName, difficultyId, raidSize, endStatus)
  self.encounterElapsedTime = time() - self.encounterStartTime
  local playerCount = GetNumGroupMembers()

  -- Check for a wipe and abort unless enable on wipes is on.
  if endStatus == 0 and not self.db.profile.enableOnWipes then
    return
  end
  
  --  Check for being in a group and abort unless enabled when soloing in on.
  if playerCount == 0 and not self.db.profile.enableWhenSoloing then
    return
  end

  -- Check whether a shot is wanted based on the instance type and/or difficulty.
  local instanceName, _, instanceDifficultyId, instanceDifficulty = GetInstanceInfo()
  local instanceType = INSTANCE_DIFFICULTY_MAP[instanceDifficultyId]
  if (instanceType == "none" and not db.profile.enableWhenOutdoors) or
     (instanceType == INSTANCE_NORMAL_DUNGEON and not db.profile.enableInNormalDungeons) or
     (instanceType == INSTANCE_HEROIC_DUNGEON and not db.profile.enableInHeroicDungeons) or
     (instanceType == INSTANCE_MYTHIC_DUNGEON and not db.profile.enableInMythicDungeons) or
     (instanceType == INSTANCE_TIMEWALKING_DUNGEON and not db.profile.enableInTimewalkingDungeons) or
     (instanceType == INSTANCE_RAIDFINDER_RAID and not db.profile.enableInRaidFinderRaids) or
     (instanceType == INSTANCE_NORMAL_RAID and not db.profile.enableInNormalRaids) or
     (instanceType == INSTANCE_HEROIC_RAID and not db.profile.enableInHeroicRaids) or
     (instanceType == INSTANCE_MYTHIC_RAID and not db.profile.enableInMythicRaids) then
    return 
  end

  -- Get the list of the players that participated, including their
  -- guilds.  Also print the duration of the encounter and the date.
  local playerCount = GetNumGroupMembers()
  local players = ''
  for i = 1, playerCount do
    local name = GetRaidRosterInfo(i)
    local _, class = UnitClass(name)
    players = players .. '|c' .. RAID_CLASS_COLORS[class].colorStr .. name .. '|r'
    local guild = GetGuildInfo(name)
    if guild ~= nil then
      players = players .. ' <' .. guild .. '>'
    end
    if i ~= playerCount then
      players = players .. ', '
    end
    if i == playerCount - 1 then
      players = players .. 'and '
    end
  end
  if playerCount == 0 then
    local _, class = UnitClass("player")
    local name = UnitName("player")
    players = "|c" .. RAID_CLASS_COLORS[class].colorStr .. name .. "|r"
  end
  local formattedElapsedTime = string.format("%.2d:%.2d", self.encounterElapsedTime/60%60, self.encounterElapsedTime%60)
  local outcome = ' was defeated by '
  if endStatus == 0 then
    outcome = ' wiped '
  end
  self.encounterInfo = '|cfff00000' .. encounterName .. '|r from |cfff00000' .. instanceName .. ' (' .. instanceDifficulty .. ')|r' .. outcome .. players .. ' in ' .. formattedElapsedTime .. ' on ' .. date("%A %B %d %Y") .. '.'

  -- Insert a delay before we actually take the screenshot. The main reason
  -- is it's nice to finish fight animations and whatnot.  Also lets
  -- the big red boss defeafed thingy appear.
  self:ScheduleTimer("PrintInfoAndTakeScreenshot", 1)
end

-- Prints the encounter information, and take a screenshot, visually
-- documenting who was in on the kill.
function BossShots:PrintInfoAndTakeScreenshot()
  self:Print(self.encounterInfo .. ' Screenshot is WoWScrnShot_' .. date():gsub("[/:]",""):gsub(" ","_") .. '.')
  Screenshot()
end
