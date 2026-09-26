local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.core = {}

addon_data.core.core_frame = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
addon_data.core.core_frame:RegisterEvent("ADDON_LOADED")

addon_data.core.all_timers = {
    addon_data.player, addon_data.target
}

local version = "1.60.1"

local load_message = L["Thank you for installing WeaponSwingTimer Version"] .. " " .. version .. 
                     " " .. L["by WatchYourSixx! Use |cFFFFC300/wst|r for more options."]
                     
addon_data.core.default_settings = {
    one_frame = false,
	welcome_message = true
}

addon_data.core.in_combat = false
addon_data.core.native_swing_available = false

-- Spells that reset the player's melee swing timer without relying on CLEU.
-- These are the spells that were active in WST's original swing-reset table.
-- They are handled on UNIT_SPELLCAST_SUCCEEDED because they are melee/queued attacks,
-- not ordinary cast-time spells.
local swing_reset_on_success = {
    DRUID = {
        [6807] = true, [6808] = true, [6809] = true, [8972] = true,
        [9745] = true, [9880] = true, [9881] = true, -- Maul
    },
    HUNTER = {
        [2973] = true, [14260] = true, [14261] = true, [14262] = true,
        [14263] = true, [14264] = true, [14265] = true, [14266] = true,
        [27014] = true, -- Raptor Strike
    },
    WARRIOR = {
        [845] = true, [7369] = true, [11608] = true, [11609] = true,
        [20569] = true, [25231] = true, -- Cleave
        [78] = true, [284] = true, [285] = true, [1608] = true,
        [11564] = true, [11565] = true, [11566] = true, [11567] = true,
        [25286] = true, [29707] = true, [30324] = true, -- Heroic Strike
        [1464] = true, [8820] = true, [11604] = true, [11605] = true,
        [25241] = true, [25242] = true, -- Slam
    },
}

-- Cast-time/channel spells that reset the swing belong here.  Keep this explicit:
-- many spells (notably Hunter shots) must NOT reset melee just because they cast.
-- We can fill this whitelist class-by-class as Forever behavior is confirmed.
local swing_reset_on_start = {
    DRUID = {}, HUNTER = {}, MAGE = {}, PALADIN = {}, PRIEST = {},
    ROGUE = {}, SHAMAN = {}, WARLOCK = {}, WARRIOR = {},
}

local function PlayerClassToken()
    local _, class = UnitClass("player")
    return class
end

local function SpellIsInResetTable(reset_table, spell_id)
    if not spell_id then return false end
    local class_spells = reset_table[PlayerClassToken()]
    return class_spells and class_spells[spell_id] == true
end

addon_data.core.HandlePlayerSwingResetSpell = function(unit, spell_id, trigger)
    if unit ~= "player" or not spell_id then return end

    local should_reset = false
    if trigger == "START" or trigger == "CHANNEL_START" then
        should_reset = SpellIsInResetTable(swing_reset_on_start, spell_id)
    elseif trigger == "SUCCEEDED" then
        should_reset = SpellIsInResetTable(swing_reset_on_success, spell_id)
    end

    if should_reset then
        addon_data.player.ResetMainSwingTimer()
    end
end

-- used to initalize settings first if they don't exist, and assign settings to individual profile db references
local function LoadAllSettings()
    addon_data.core.LoadSettings()
    addon_data.player.LoadSettings()
    addon_data.target.LoadSettings()
    addon_data.hunter.LoadSettings()
    addon_data.range.LoadSettings()
	addon_data.castbar.LoadSettings()
end

addon_data.core.RestoreAllDefaults = function()
    addon_data.db:ResetProfile()
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

local function InitializeAllVisuals()
    addon_data.player.InitializeVisuals()
    addon_data.target.InitializeVisuals()
    addon_data.hunter.InitializeVisuals()
    addon_data.range.InitializeVisuals()
    addon_data.castbar.InitializeVisuals()
    addon_data.config.InitializeVisuals()
end


addon_data.core.UpdateAllVisualsOnSettingsChange = function()
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.target.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.range.UpdateVisualsOnSettingsChange()
	addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.player.UpdateConfigPanelValues()
    addon_data.target.UpdateConfigPanelValues()
    addon_data.hunter.UpdateConfigPanelValues()
    addon_data.range.UpdateConfigPanelValues()
    addon_data.castbar.UpdateConfigPanelValues()
end

addon_data.core.LoadSettings = function()
    -- If the carried over settings dont exist then make them
    if not character_core_settings then
        character_core_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.core.default_settings) do
        if character_core_settings[setting] == nil then
            character_core_settings[setting] = value
        end
    end
end

local function CoreFrame_OnUpdate(self, elapsed)
    addon_data.player.OnUpdate(elapsed)
    addon_data.target.OnUpdate(elapsed)
    addon_data.hunter.OnUpdate(elapsed)
	addon_data.castbar.OnUpdate(elapsed)
end

addon_data.core.MissHandler = function(unit, miss_type, is_offhand, is_player)
    if miss_type == "PARRY" then
        if unit == "player" then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = addon_data.target.main_weapon_speed * 0.2

            if min_swing_time >= addon_data.target.main_swing_timer then
                -- do nothing
			else
                addon_data.target.main_swing_timer = addon_data.target.main_swing_timer - (addon_data.target.main_weapon_speed * 0.4)

                if addon_data.target.main_swing_timer < min_swing_time then
                    addon_data.target.main_swing_timer = min_swing_time
                end
            end
            if not is_offhand then
			-- resets swing timer if it's not an extra attack, attempt to fix random resets mid-swing
				if (addon_data.player.extra_attacks_flag == false) then
					addon_data.player.ResetMainSwingTimer()
				end
			addon_data.player.extra_attacks_flag = false
            else
                addon_data.player.ResetOffSwingTimer()
            end
        elseif unit == "target" and is_player then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = addon_data.player.main_weapon_speed * 0.2

            if min_swing_time >= addon_data.player.main_swing_timer then
                -- do nothing
			else
                addon_data.player.main_swing_timer = addon_data.player.main_swing_timer - (addon_data.player.main_weapon_speed * 0.4)

                if addon_data.player.main_swing_timer < min_swing_time then
                    addon_data.player.main_swing_timer = min_swing_time
                end
            end
            if not is_offhand then
                addon_data.target.ResetMainSwingTimer()
            else
                addon_data.target.ResetOffSwingTimer()
            end
		elseif unit == "target" then
            -- do nothing
        else
            addon_data.utils.PrintMsg(L["Unexpected Unit Type in MissHandler()."])
        end
    else
        if unit == "player" then
            if not is_offhand then
                if (addon_data.player.extra_attacks_flag == false) then
			addon_data.player.ResetMainSwingTimer()
		end
		addon_data.player.extra_attacks_flag = false
            else
                addon_data.player.ResetOffSwingTimer()
            end 
        elseif unit == "target" then
            if not is_offhand then
                addon_data.target.ResetMainSwingTimer()
            else
                addon_data.target.ResetOffSwingTimer()
            end 
		else
            addon_data.utils.PrintMsg(L["Unexpected Unit Type in MissHandler()."])
        end
    end
end

-- loads Ace3 DB for storing profiles and creates a func for updating settings
function addon_data.core.InitDB()
    local AceDB = LibStub("AceDB-3.0")

    addon_data.db = AceDB:New("WSTProfileDB", addon_data.defaults, true)
    -- added legacy settings check that was per character, for migrating into account wide
    addon_data.core.CheckLegacySettingsOrWarn()
    addon_data.core.MigrateLegacyPerCharToProfile()

    local function RefreshFromDB()
        addon_data.db.profile.range = addon_data.db.profile.range or {}

        character_core_settings    = addon_data.db.profile.core
        character_player_settings  = addon_data.db.profile.player
        character_target_settings  = addon_data.db.profile.target
        character_hunter_settings  = addon_data.db.profile.hunter
        character_range_settings   = addon_data.db.profile.range
        character_castbar_settings = addon_data.db.profile.castbar

        if addon_data.core.visuals_initialized then
            addon_data.core.UpdateAllVisualsOnSettingsChange()
        end
    end

    addon_data.core.RefreshFromDB = RefreshFromDB
    RefreshFromDB()
    
    addon_data.db:RegisterCallback("OnProfileChanged", RefreshFromDB)
    addon_data.db:RegisterCallback("OnProfileCopied",  RefreshFromDB)
    addon_data.db:RegisterCallback("OnProfileReset",   RefreshFromDB)
end

function addon_data.core.CheckLegacySettingsOrWarn()
    if not addon_data.db then return end

    -- Per-character storage inside AceDB
    addon_data.db.char = addon_data.db.char or {}

    -- Prevent spam
    if addon_data.db.char.warnedMissingLegacy then
        return
    end

    local function HasLegacySettings()
        local function hasData(t)
            return type(t) == "table" and next(t) ~= nil
        end

        return
            hasData(_G.character_core_settings) or
            hasData(_G.character_player_settings) or
            hasData(_G.character_target_settings) or
            hasData(_G.character_hunter_settings) or
            hasData(_G.character_castbar_settings)
    end

    -- No legacy data found
    if not HasLegacySettings() then
        addon_data.db.char.warnedMissingLegacy = true

        addon_data.utils.PrintMsg(
            "WST could not find your old per-character settings.\n" ..
            "If you have a .bak file, please restore it:\n" ..
            "|cffaaaaaaWTF/Account/<AccountName>/<ServerName>/SavedVariables/WeaponSwingTimer.lua.bak|r\n" ..
            "Create a copy, and rename the .bak file to WeaponSwingTimer.lua\n" ..
            "Then reload the game to migrate your settings into a profile automatically."
        )
    end
end

function addon_data.core.MigrateLegacyPerCharToProfile()
    if not addon_data.db then return end

    -- per-character storage inside AceDB
    addon_data.db.char = addon_data.db.char or {}
    addon_data.db.char.migratedLegacy = addon_data.db.char.migratedLegacy or {}

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local key = playerName .. " - " .. realmName

    -- already migrated on this character
    if addon_data.db.char.migratedLegacy[key] then
        return
    end

    -- Detect whether legacy data exists
    local function hasData(t) 
        return type(t) == "table" and next(t) ~= nil
    end

    local legacyExists =
        hasData(_G.character_core_settings) or
        hasData(_G.character_player_settings) or
        hasData(_G.character_target_settings) or
        hasData(_G.character_hunter_settings) or
        hasData(_G.character_castbar_settings)

    if not legacyExists then
        return
    end

    -- Create/use a per-character profile name
    local profileName = key

    -- Create profile if it doesn't exist
    local profiles = addon_data.db:GetProfiles()
    local found = false
    for _, p in ipairs(profiles) do
        if p == profileName then found = true break end
    end
    if not found then
        addon_data.db:SetProfile(profileName)
        addon_data.utils.PrintMsg("WST automatically imported your previous settings and saved under" .. " " .. profileName)
    else
        addon_data.db:SetProfile(profileName)
    end

    addon_data.db.profile.core    = addon_data.utils.DeepCopy(_G.character_core_settings or {}, {})
    addon_data.db.profile.player  = addon_data.utils.DeepCopy(_G.character_player_settings or {}, {})
    addon_data.db.profile.target  = addon_data.utils.DeepCopy(_G.character_target_settings or {}, {})
    addon_data.db.profile.hunter  = addon_data.utils.DeepCopy(_G.character_hunter_settings or {}, {})
    addon_data.db.profile.range   = addon_data.utils.DeepCopy(_G.character_range_settings or {}, {})
    addon_data.db.profile.castbar = addon_data.utils.DeepCopy(_G.character_castbar_settings or {}, {})

    -- Mark migrated for this character
    addon_data.db.char.migratedLegacy[key] = true

end

local function OnAddonLoaded(self)
    -- Register events first (OnUpdate registered after visuals are initialized)
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    addon_data.core.core_frame:RegisterEvent("UNIT_COMBAT")

    -- WoW 12.x / Forever blocks COMBAT_LOG_EVENT_UNFILTERED registration.
    -- Modern replacements are used instead.
    addon_data.core.cleu_available = false

    addon_data.core.core_frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    addon_data.core.core_frame:RegisterEvent("START_AUTOREPEAT_SPELL")
    addon_data.core.core_frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_START")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")

    -- WoW Forever provides authoritative swing timing through PLAYER_SWING.
    -- pcall keeps the old fallback usable on clients that do not expose it.
    local nativeSwingOK = pcall(
        addon_data.core.core_frame.RegisterEvent,
        addon_data.core.core_frame,
        "PLAYER_SWING"
    )
    addon_data.core.native_swing_available = nativeSwingOK

    -- Load the settings for the core and all timers
    -- load profiles defaults
    addon_data.defaults = {
    profile = {
        core    = addon_data.core.default_settings,
        hunter  = addon_data.hunter.default_settings,
        range   = addon_data.range.default_settings,
        player  = addon_data.player.default_settings,
        target  = addon_data.target.default_settings,
        castbar = addon_data.castbar.default_settings,
        }
    }
    -- initialize profiles Ace3 database
    addon_data.core.InitDB()
    LoadAllSettings()          
    InitializeAllVisuals()
    addon_data.core.visuals_initialized = true

    -- Now that visuals are initialized, attach the OnUpdate script
    addon_data.core.core_frame:SetScript("OnUpdate", CoreFrame_OnUpdate)
    -- Any other misc operations that happen at the start
    addon_data.player.ZeroizeSwingTimers()
    addon_data.target.ZeroizeSwingTimers()
	
    if character_core_settings.welcome_message then	
		addon_data.utils.PrintMsg(load_message)	
	end
end


local function WST_ApplyParryHaste(unit)
    local speed
    local timer

    if unit == "player" then
        speed = addon_data.player.main_weapon_speed
        timer = addon_data.player.main_swing_timer
    elseif unit == "target" then
        speed = addon_data.target.main_weapon_speed
        timer = addon_data.target.main_swing_timer
    else
        return
    end

    if not speed or not timer or speed <= 0 or timer <= 0 then
        return
    end

    -- Same rule as the legacy CLEU MissHandler:
    -- reduce remaining swing time by 40% of weapon speed,
    -- but never reduce it below 20% of weapon speed.
    local min_swing_time = speed * 0.20

    if timer <= min_swing_time then
        return
    end

    local new_timer = timer - (speed * 0.40)
    if new_timer < min_swing_time then
        new_timer = min_swing_time
    end

    if unit == "player" then
        addon_data.player.main_swing_timer = new_timer
    else
        addon_data.target.main_swing_timer = new_timer
    end

end

local function CoreFrame_OnEvent(self, event, ...)
    local args = {...}
    if event == "ADDON_LOADED" then
        if args[1] == "WeaponSwingTimer" then
            OnAddonLoaded()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon_data.core.in_combat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon_data.core.in_combat = true
    elseif event == "PLAYER_TARGET_CHANGED" then
        addon_data.target.OnPlayerTargetChanged()

    elseif event == "UNIT_COMBAT" then
        -- UNIT_COMBAT reports the unit receiving the combat result.
        -- A PARRY result means that unit performed the parry, so its
        -- own next main-hand swing receives parry haste.
        local unit, action = ...
        if unit == "player" and addon_data.target.OnEstimatedPlayerCombatResult then
            addon_data.target.OnEstimatedPlayerCombatResult(action)
        end
        if action == "PARRY" then
            WST_ApplyParryHaste(unit)
        end
    elseif event == "PLAYER_SWING" then
        local swingDuration, swingType = ...

        -- Main/off-hand and ranged swings all use Blizzard's authoritative
        -- duration. Existing combat-log logic remains for special mechanics,
        -- target swings, parry handling, and legacy fallback behavior.
        if addon_data.player.OnPlayerSwing then
            addon_data.player.OnPlayerSwing(swingDuration, swingType)
        end
        if addon_data.hunter.OnPlayerSwing then
            addon_data.hunter.OnPlayerSwing(swingDuration, swingType)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local combat_info = {CombatLogGetCurrentEventInfo()}
        addon_data.player.OnCombatLogUnfiltered(combat_info)
        addon_data.target.OnCombatLogUnfiltered(combat_info)
		addon_data.hunter.OnCombatLogUnfiltered(combat_info)
		addon_data.castbar.OnCombatLogUnfiltered(combat_info)
    elseif event == "UNIT_INVENTORY_CHANGED" then
        addon_data.player.OnInventoryChange()
        addon_data.target.OnInventoryChange()
		addon_data.hunter.OnInventoryChange()
    elseif event == "START_AUTOREPEAT_SPELL" then
        addon_data.hunter.OnStartAutorepeatSpell()
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        addon_data.hunter.OnStopAutorepeatSpell()
    elseif event == "UNIT_SPELLCAST_SENT" then
        -- UNIT_SPELLCAST_SENT: unit, target, castGUID, spellID
        if addon_data.castbar.OnUnitSpellCastSent then
            addon_data.castbar.OnUnitSpellCastSent(
                args[1], args[2], args[3], args[4]
            )
        end
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        -- UNIT_SPELLCAST_DELAYED: unit, castGUID, spellID, castBarID
        if addon_data.castbar.OnUnitSpellCastDelayed then
            addon_data.castbar.OnUnitSpellCastDelayed(
                args[1], args[2], args[3], args[4]
            )
        end
    elseif event == "UNIT_SPELLCAST_START" then
        addon_data.core.HandlePlayerSwingResetSpell(args[1], args[3], "START")
        if addon_data.hunter.OnUnitSpellCastStart then
            addon_data.hunter.OnUnitSpellCastStart(args[1], args[3])
        end
        if addon_data.castbar.OnUnitSpellCastStart then
            addon_data.castbar.OnUnitSpellCastStart(args[1], args[3])
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        addon_data.core.HandlePlayerSwingResetSpell(args[1], args[3], "CHANNEL_START")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        addon_data.core.HandlePlayerSwingResetSpell(args[1], args[3], "SUCCEEDED")
        addon_data.hunter.OnUnitSpellCastSucceeded(args[1], args[3])
		addon_data.castbar.OnUnitSpellCastSucceeded(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_FAILED" then
		addon_data.castbar.OnUnitSpellCastFailed(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		addon_data.hunter.OnUnitSpellCastInterrupted(args[1], args[3])
		addon_data.castbar.OnUnitSpellCastInterrupted(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_FAILED_QUIET" then
        addon_data.hunter.OnUnitSpellCastFailedQuiet(args[1], args[3])
    end
end

-- Add a slash command to bring up the config window
SLASH_WEAPONSWINGTIMER_CONFIG1 = "/WeaponSwingTimer"
SLASH_WEAPONSWINGTIMER_CONFIG2 = "/weaponswingtimer"
SLASH_WEAPONSWINGTIMER_CONFIG3 = "/wst"
SlashCmdList["WEAPONSWINGTIMER_CONFIG"] = function(option)
    if Settings and Settings.OpenToCategory and addon_data.config.settingsCategoryID then
        Settings.OpenToCategory(addon_data.config.settingsCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- Fallback for older clients (called twice to work around a known bug)
        InterfaceOptionsFrame_OpenToCategory("WeaponSwingTimer")
        InterfaceOptionsFrame_OpenToCategory("WeaponSwingTimer")
    end
end

-- Setup the core of the addon (This is like calling main in C)
addon_data.core.core_frame:SetScript("OnEvent", CoreFrame_OnEvent)
