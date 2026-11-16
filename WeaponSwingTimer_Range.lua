local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.range = {}

addon_data.range.default_settings = {
    bar_font = "default",
    bar_texture = "default",
    enabled = false,
    width = 300,
    height = 12,
    fontsize = 10,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -290,
    in_combat_alpha = 1.0,
    ooc_alpha = 0.5,
    backplane_alpha = 0.5,
    is_locked = false,
    show_text = true,
    show_sweet_spot = false,
    show_sniper_shot = false,
    hide_no_target = false,
    hide_dead_target = false,
    text_melee = L["0-5 yd  •  MELEE"] or "0-5 yd  •  MELEE",
    text_deadzone = L["5-8 yd  •  DEAD ZONE"] or "5-8 yd  •  DEAD ZONE",
    text_sweet_spot = "8-11 yd  •  SWEET SPOT",
    text_close = L["8-15 yd"] or "8-15 yd",
    text_ranged = L["8-35 yd"] or "8-35 yd",
    text_sniper_shot = "35-45 yd  •  SNIPER SHOT",
    text_far = L["35-100 yd"] or "35-100 yd",
    text_out = L["100+ yd  •  OUT OF RANGE"] or "100+ yd  •  OUT OF RANGE",
    text_unknown = L["NO TARGET"] or "NO TARGET",

    show_border = false,
    classic_bars = true,

    melee_r = 0.85, melee_g = 0.20, melee_b = 0.20, melee_a = 1.0,
    deadzone_r = 1.00, deadzone_g = 0.90, deadzone_b = 0.10, deadzone_a = 1.0,
    sweet_spot_r = 0.0, sweet_spot_g = 0.85, sweet_spot_b = 0.8, sweet_spot_a = 1.0,
    close_r = 0.95, close_g = 0.75, close_b = 0.10, close_a = 1.0,
    ranged_r = 0.20, ranged_g = 0.75, ranged_b = 0.20, ranged_a = 1.0,
    sniper_shot_r = 0.75, sniper_shot_g = 0.4, sniper_shot_b = 0.95, sniper_shot_a = 1.0,
    far_r = 0.35, far_g = 0.55, far_b = 0.90, far_a = 1.0,
    out_r = 0.55, out_g = 0.55, out_b = 0.55, out_a = 1.0,
    unknown_r = 0.65, unknown_g = 0.65, unknown_b = 0.65, unknown_a = 1.0,
}

addon_data.range.update_elapsed = 0
addon_data.range.current_text = ""
addon_data.range.current_key = "none"

local function GetRangeColor(settings, key)
    local prefix = key
    if settings[prefix .. "_r"] == nil then
        prefix = "unknown"
    end

    return {
        settings[prefix .. "_r"] or 0.65,
        settings[prefix .. "_g"] or 0.65,
        settings[prefix .. "_b"] or 0.65,
        settings[prefix .. "_a"] or 1.0,
    }
end


-- Experimental non-Hunter range probes.
-- These deliberately use spell names + live spellbook data rather than hard-coded
-- spell IDs/ranges so Forever can resolve the player's learned version.
local CLASS_RANGE_PROBES = {
    WARRIOR = {"Charge", "Intercept", "Heroic Throw"},
    PALADIN = {"Hammer of Justice", "Judgment"},
    ROGUE = {"Kick", "Blind", "Throw"},
    MAGE = {"Fire Blast", "Counterspell", "Polymorph"},
    PRIEST = {"Psychic Scream", "Silence", "Mind Blast"},
    WARLOCK = {"Death Coil", "Fear", "Shadow Bolt"},
    DRUID = {"Feral Charge", "Growl", "Faerie Fire", "Entangling Roots"},
    SHAMAN = {"Earth Shock", "Purge", "Lightning Bolt"},
}

-- Range checks intentionally use the player's actual spell names.
-- This avoids querying obsolete/unlearned rank IDs, which can return misleading
-- range results on Forever.
local AUTO_SHOT_ID = 75

local function NormalizeRangeResult(result)
    if issecretvalue and issecretvalue(result) then return nil end
    if result == true or result == 1 then
        return true
    elseif result == false or result == 0 then
        return false
    end
    return nil
end

local function SpellBookSpellInRange(spell_identifier)
    if not UnitExists("target") then
        return nil
    end

    if C_SpellBook and
       C_SpellBook.FindSpellBookSlotForSpell and
       C_SpellBook.IsSpellBookItemInRange then

        local ok, slot_index, spell_bank = pcall(
            C_SpellBook.FindSpellBookSlotForSpell,
            spell_identifier
        )

        if ok and slot_index and spell_bank then
            local range_ok, result = pcall(
                C_SpellBook.IsSpellBookItemInRange,
                slot_index,
                spell_bank,
                "target"
            )

            if range_ok then
                local in_range = NormalizeRangeResult(result)
                if in_range ~= nil then return in_range end
            end
        end
    end

    -- Compatibility fallbacks for clients/builds where the spellbook API
    -- cannot resolve the item.
    if C_Spell and C_Spell.IsSpellInRange then
        local ok, result = pcall(C_Spell.IsSpellInRange, spell_identifier, "target")
        if ok then
            local in_range = NormalizeRangeResult(result)
            if in_range ~= nil then return in_range end
        end
    end
    if IsSpellInRange then
        local spell_name = spell_identifier
        if type(spell_identifier) == "number" and C_Spell and C_Spell.GetSpellName then
            spell_name = C_Spell.GetSpellName(spell_identifier)
        end

        if spell_name then
            local ok, result = pcall(IsSpellInRange, spell_name, "target")
            if ok then
                return NormalizeRangeResult(result)
            end
        end
    end

    return nil
end

local function HasSpellBookSpell(spell_identifier)
    if not C_SpellBook or not C_SpellBook.FindSpellBookSlotForSpell then
        return false
    end

    local ok, slot_index = pcall(
        C_SpellBook.FindSpellBookSlotForSpell,
        spell_identifier
    )

    return ok and slot_index ~= nil
end

local function NativeMeleeInRange()
    -- Raptor Strike is intentionally NOT used here. On Forever its range API
    -- reports true outside actual melee range, so it is not a valid 5-yard
    -- breakpoint. Wing Clip is the reliable Hunter melee-range check.
    if not HasSpellBookSpell("Wing Clip") then
        return nil
    end

    return SpellBookSpellInRange("Wing Clip")
end

-- Share the Hunter melee probe with diagnostics without enabling the range bar.
addon_data.range.GetHunterMeleeRange = function()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" or not UnitExists("target") or UnitIsDead("target")
        or not UnitCanAttack("player", "target") then
        return nil
    end
    return NativeMeleeInRange()
end

local function NativeSwingInRange(hand)
    local swing_type = Enum and Enum.PlayerSwingType and Enum.PlayerSwingType[hand]
    if C_SwingTimer and C_SwingTimer.IsTargetWithinSwingRange and swing_type ~= nil then
        local ok, result = pcall(
            C_SwingTimer.IsTargetWithinSwingRange,
            swing_type
        )
        if ok then
            local in_range = NormalizeRangeResult(result)
            if in_range ~= nil then return in_range end
        end
    end

end

local function NativeRangedInRange()
    local result = NativeSwingInRange("Ranged")
    if result ~= nil then return result end
    return SpellBookSpellInRange("Auto Shot")
end

-- Fixed hostile-item breakpoints from the Classic/Forever range-check tables.
local range_items = {
    [5] = {8149, 15826, 16308, 17117},
    [10] = {9606, 9618, 9619, 9620, 9621},
    [35] = {1258, 1399, 1402, 8688},
}
local requested_items = {}

local function ItemRange(yards, prefer_positive)
    local check = C_Item and C_Item.IsItemInRange or IsItemInRange
    if not check then return nil end
    local items = range_items[yards]
    if not requested_items[yards] and C_Item and C_Item.RequestLoadItemDataByID then
        requested_items[yards] = true
        for _, id in ipairs(items) do pcall(C_Item.RequestLoadItemDataByID, id) end
    end
    local answered_no
    for _, id in ipairs(items) do
        local ok, result = pcall(check, id, "target")
        if ok then
            local in_range = NormalizeRangeResult(result)
            if in_range == true then return true, id end
            if in_range == false then
                if not prefer_positive then return false, id end
                answered_no = id
            end
        end
    end
    if answered_no then return false, answered_no end
end

local function SweetSpotTradeRange()
    if CheckInteractDistance then
        local ok, result = pcall(CheckInteractDistance, "target", 2)
        if ok then return NormalizeRangeResult(result) end
    end
end

local function SweetSpotRange()
    if SweetSpotTradeRange() == true then return true, 11 end
    -- A hostile target can return false for the trade probe even at shooting
    -- distance. Still check the short-range items, and do not infer >11 yd
    -- solely from a negative trade response.
    return ItemRange(10, true), 10
end

local function GenericMeleeInRange()
    local result = NativeSwingInRange("MainHand")
    if result ~= nil then return result end
    return ItemRange(5)
end

local function IsCloseFallback()
    if not CheckInteractDistance then
        return false
    end

    -- Auto Shot returning false can mean either "too close" (<8 yd) or
    -- "too far" (>max range). CheckInteractDistance index 4 is ~28 yd.
    -- Therefore, if Auto Shot is false but the target is still within this
    -- interaction distance, it must be on the CLOSE side of Auto Shot's
    -- minimum range rather than beyond its maximum range.
    --
    -- Index 1 is also ~28 yd on current clients, so use it as a fallback
    -- in case index 4 is unavailable/unreliable on a particular build.
    local ok4, result4 = pcall(CheckInteractDistance, "target", 4)
    if ok4 and NormalizeRangeResult(result4) == true then
        return true
    end

    local ok1, result1 = pcall(CheckInteractDistance, "target", 1)
    if ok1 and NormalizeRangeResult(result1) == true then
        return true
    end

    return false
end

local function GetSpellRangeInfo(spell_identifier)
    if not C_Spell or not C_Spell.GetSpellInfo then
        return nil, nil, nil
    end

    local ok, info = pcall(C_Spell.GetSpellInfo, spell_identifier)
    if not ok or type(info) ~= "table" then
        return nil, nil, nil
    end

    local min, max = info.minRange, info.maxRange
    if issecretvalue then
        if issecretvalue(min) then min = nil end
        if issecretvalue(max) then max = nil end
    end
    return tonumber(min), tonumber(max), info.name
end

local sniper_ids = {1310786, 1310785, 1310687}
local HAWK_EYE_NODE = 105013
local function HawkEyeBonus()
    if C_Traits and C_Traits.GetNodeInfo then
        local ok, rank = pcall(function()
            local group = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup
                and C_SpecializationInfo.GetActiveSpecGroup()
            local config = group and GetCombatConfigIDForSpecGroup and GetCombatConfigIDForSpecGroup(group)
            if not config and C_ClassTalents and C_ClassTalents.GetActiveConfigID then
                config = C_ClassTalents.GetActiveConfigID()
            end
            local node = config and C_Traits.GetNodeInfo(config, HAWK_EYE_NODE)
            if node then return node.activeRank end
        end)
        if ok and not (issecretvalue and issecretvalue(rank)) and type(rank) == "number" and rank >= 0 and rank <= 3 then
            return 2 * rank
        end
    end
end

local function SniperBuffActive()
    local check = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not check then return false end
    for _, id in ipairs(sniper_ids) do
        local ok, aura = pcall(check, id)
        if ok and not (issecretvalue and issecretvalue(aura)) and type(aura) == "table" then return true end
    end
    return false
end

local function ShotMaxRange(spell, base, bonus)
    local _, reported = GetSpellRangeInfo(spell)
    -- Some clients report base range and others include modifiers. Use the
    -- larger value so a talent or buff is never counted twice.
    return math.floor(math.max(reported or 0, base + bonus) + 0.5)
end

local function FormatShotBand(lower, upper, label)
    return string.format("%d-%d yd  •  %s", lower, upper, label)
end

local function SniperRange()
    for _, id in ipairs(sniper_ids) do
        if HasSpellBookSpell(id) then
            local result = SpellBookSpellInRange(id)
            if result ~= nil then return result, id end
        end
    end
end

local function RangeKeyFromMax(max_range)
    max_range = tonumber(max_range)
    if not max_range then
        return "unknown"
    elseif max_range <= 5 then
        return "melee"
    elseif max_range <= 15 then
        return "close"
    elseif max_range <= 40 then
        return "ranged"
    end
    return "far"
end

local function GetGenericClassRangeBand(class)
    local probes = CLASS_RANGE_PROBES[class]
    if not probes then
        return L["NO CLASS RANGE PROBE"], "unknown"
    end

    local known = {}

    for _, spell_name in ipairs(probes) do
        if HasSpellBookSpell(spell_name) then
            local in_range = SpellBookSpellInRange(spell_name)
            local min_range, max_range, resolved_name =
                GetSpellRangeInfo(spell_name)

            known[#known + 1] = {
                name = resolved_name or spell_name,
                in_range = in_range,
                min_range = tonumber(min_range),
                max_range = tonumber(max_range),
            }
        end
    end

    if #known == 0 then
        return L["NO KNOWN RANGE PROBE"], "unknown"
    end

    table.sort(known, function(a, b)
        return (a.max_range or 9999) < (b.max_range or 9999)
    end)

    -- Find the tightest successful breakpoint first.
    for i, probe in ipairs(known) do
        if probe.in_range == true then
            local min_range = probe.min_range or 0
            local max_range = probe.max_range

            if max_range and max_range > 0 then
                -- If this is the first/closest known probe, use it directly.
                if i == 1 then
                    if min_range > 0 then
                        return string.format(L["%s: %d-%d yd"], probe.name,
                               math.floor(min_range + 0.5),
                               math.floor(max_range + 0.5)),
                               RangeKeyFromMax(max_range)
                    end

                    return string.format(L["%s: 0-%d yd"], probe.name,
                           math.floor(max_range + 0.5)),
                           RangeKeyFromMax(max_range)
                end

                -- Missing a closer breakpoint? Merge upward into this broader
                -- successful range rather than inventing an unknown/close gap.
                local previous = known[i - 1]
                local lower = 0

                if previous and previous.max_range then
                    lower = math.floor(previous.max_range + 0.5)
                elseif min_range and min_range > 0 then
                    lower = math.floor(min_range + 0.5)
                end

                return string.format(L["%d-%d yd"], lower,
                       math.floor(max_range + 0.5)),
                       RangeKeyFromMax(max_range)
            end

            return string.format(L["%s: IN RANGE"], probe.name), "unknown"
        end
    end

    -- Nothing is in range. If every known breakpoint explicitly says false,
    -- we're beyond the widest tested ability.
    local all_false = true
    for _, probe in ipairs(known) do
        if probe.in_range ~= false then
            all_false = false
            break
        end
    end

    if all_false then
        return L["OUT OF TESTED ABILITY RANGE"], "out"
    end

    -- One or more range APIs are unavailable/nil. Fall back to the broadest
    -- known breakpoint rather than showing a fake intermediate band.
    local broadest = known[#known]
    if broadest and broadest.max_range then
        return string.format(L["0-%d yd"],
               math.floor(broadest.max_range + 0.5)),
               RangeKeyFromMax(broadest.max_range)
    end

    return L["RANGE UNAVAILABLE"], "unknown"
end

addon_data.range.GetRangeBand = function()
    if not UnitExists("target") or UnitIsDead("target") then
        return nil, "none"
    end

    if not UnitCanAttack("player", "target") then
        return nil, "none"
    end

    local _, class = UnitClass("player")
    if class ~= "HUNTER" then
        if GenericMeleeInRange() == true then return L["0-5 yd  •  MELEE"], "melee" end
        return GetGenericClassRangeBand(class)
    end

    -- Hunter melee breakpoint: Wing Clip only.
    local has_melee_check = HasSpellBookSpell("Wing Clip")
    local melee = NativeMeleeInRange()
    if melee == true then
        return L["0-5 yd  •  MELEE"], "melee"
    end

    local scatter = SpellBookSpellInRange("Scatter Shot")
    local ranged = NativeRangedInRange()
    local mark = SpellBookSpellInRange("Hunter's Mark")
    local settings = character_range_settings
    local show_sniper = settings and settings.show_sniper_shot
    local hawk = HawkEyeBonus() or 0
    local sniper_buff = show_sniper and SniperBuffActive()
    local auto_max = ShotMaxRange(AUTO_SHOT_ID, 35, hawk + (sniper_buff and 10 or 0))
    -- If the aura is unreadable but the spell reports exactly the boosted
    -- range, use that as evidence of Sniper's bonus.
    if show_sniper and auto_max == 45 + hawk then sniper_buff = true end
    -- Live spell info can supply Hawk Eye's bonus if trait data is unavailable.
    if hawk == 0 and not sniper_buff and
        auto_max >= 37 and auto_max <= 41 and auto_max % 2 == 1 then
        hawk = auto_max - 35
    end

    -- Auto Shot has an 8 yd minimum. If we're not in melee, Auto Shot is
    -- unavailable, and Scatter is still in range, this is the dead zone.
    if ranged == false and scatter == true then
        return L["5-8 yd  •  DEAD ZONE"], "deadzone"
    end

    if ranged == true then
        local lower = 8
        if character_range_settings and character_range_settings.show_sweet_spot then
            local in_sweet_spot, upper = SweetSpotRange()
            if in_sweet_spot then
                local text = upper == 11 and addon_data.range.default_settings.text_sweet_spot or "8-10 yd  •  SWEET SPOT"
                return text, "sweet_spot"
            elseif in_sweet_spot == false then
                lower = upper
            end
        end
        if show_sniper and sniper_buff and scatter ~= true and ItemRange(35) == false then
            return FormatShotBand(35, auto_max, "SNIPER BUFF"), "sniper_shot"
        end

        if HasSpellBookSpell("Scatter Shot") then
            if scatter == true then
                if lower ~= 8 then return string.format(L["%d-%d yd"], lower, 15), "close" end
                return L["8-15 yd"], "close"
            end
            return string.format(L["15-%d yd"], auto_max), "ranged"
        end

        -- Without Scatter Shot there is no reliable 15-yard breakpoint.
        if lower ~= 8 then return string.format(L["%d-%d yd"], lower, auto_max), "ranged" end
        return string.format(L["8-%d yd"], auto_max), "ranged"
    end

    -- If the native ranged check says false, distinguish "too close" from
    -- "too far". CheckInteractDistance index 3 provides a short-range fallback
    -- that covers the small transition area even when Scatter Shot isn't learned
    -- or its spell ID is unavailable on the current Forever build.
    if ranged == false then
        if IsCloseFallback() then
            if has_melee_check then
                return L["5-8 yd  •  DEAD ZONE"], "deadzone"
            end
            return L["<8 yd"], "deadzone"
        end

        if show_sniper and ItemRange(35) ~= true then
            local sniper_in_range, spell = SniperRange()
            if sniper_in_range == true then
                local sniper_max = ShotMaxRange(spell, 45, hawk)
                if sniper_max > auto_max then
                    return FormatShotBand(auto_max, sniper_max, "SNIPER SHOT"), "sniper_shot"
                end
                return "SNIPER SHOT IN RANGE", "sniper_shot"
            end
            if sniper_in_range == false and mark == true then
                return string.format(L["%d-%d yd"], math.max(auto_max, ShotMaxRange(spell, 45, hawk)), 100), "far"
            end
        end

        if mark == true then
            if auto_max > 35 then return string.format(L["%d-%d yd"], auto_max, 100), "far" end
            return L["35-100 yd"], "far"
        elseif mark == false then
            return L["100+ yd  •  OUT OF RANGE"], "out"
        end

        return L["OUT OF SHOT RANGE"], "out"
    end

    -- Native range can briefly be nil during target transitions. Use the spell
    -- ladder instead of flashing "out of range".
    if scatter == true then
        return L["5-15 yd"], "close"
    end

    if mark == true then
        return L["Within 100 yd"], "unknown"
    elseif mark == false then
        return L["100+ yd  •  OUT OF RANGE"], "out"
    end

    return L["Range unavailable"], "unknown"
end


-- Temporary diagnostics. Run /wstrangedebug while targeting something.
local function DebugValue(value)
    if value == nil then return "nil" end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then return "<secret>" end
    end
    local ok, text = pcall(tostring, value)
    return ok and text or "<unprintable>"
end

local function DebugCall(label, func, ...)
    if type(func) ~= "function" then
        print("|cffffcc00WST Range:|r " .. label .. " = API MISSING")
        return nil
    end

    local results = {pcall(func, ...)}
    local ok = table.remove(results, 1)
    if not ok then
        print("|cffffcc00WST Range:|r " .. label .. " = ERROR: " .. DebugValue(results[1]))
        return nil
    end

    local parts = {}
    for i = 1, #results do
        parts[#parts + 1] = DebugValue(results[i])
    end
    if #parts == 0 then parts[1] = "nil" end

    print("|cffffcc00WST Range:|r " .. label .. " = " .. table.concat(parts, ", "))
    return unpack(results)
end

addon_data.range.DumpDebug = function()
    print("|cff00ff00========== WST RANGE DEBUG ==========|r")

    local _, class = UnitClass("player")
    print("|cffffcc00WST Range:|r class=" .. DebugValue(class) ..
          " target=" .. DebugValue(UnitName("target")) ..
          " exists=" .. DebugValue(UnitExists("target")) ..
          " attackable=" .. DebugValue(UnitCanAttack("player", "target")))

    if class == "HUNTER" then
        local has_wing = HasSpellBookSpell("Wing Clip")
        local wing = SpellBookSpellInRange("Wing Clip")
        local has_scatter = HasSpellBookSpell("Scatter Shot")
        local scatter = SpellBookSpellInRange("Scatter Shot")
        local ranged = NativeRangedInRange()
        local mark = SpellBookSpellInRange("Hunter's Mark")

        print("|cffffcc00WST Range:|r Wing Clip known=" ..
              DebugValue(has_wing) .. " inRange=" .. DebugValue(wing))
        print("|cffffcc00WST Range:|r Scatter Shot known=" ..
              DebugValue(has_scatter) .. " inRange=" .. DebugValue(scatter))
        print("|cffffcc00WST Range:|r Auto Shot/native ranged=" ..
              DebugValue(ranged))
        local sniper, spell = SniperRange()
        print("|cffffcc00WST Range:|r Hawk Eye bonus=" .. DebugValue(HawkEyeBonus()) ..
              " Sniper range=" .. DebugValue(sniper) .. " spell=" .. DebugValue(spell) ..
              " Sniper buff=" .. DebugValue(SniperBuffActive()) .. " item35=" .. DebugValue(ItemRange(35)))
        print("|cffffcc00WST Range:|r Hunter's Mark=" ..
              DebugValue(mark))

        if CheckInteractDistance then
            for i = 1, 4 do
                DebugCall(
                    "CheckInteractDistance " .. i,
                    CheckInteractDistance,
                    "target",
                    i
                )
            end
        end

        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
            local trade = SweetSpotTradeRange()
            local item, id = ItemRange(10, true)
            local settings = character_range_settings
            print("|cffffcc00WST Range:|r Sweet spot enabled=" .. DebugValue(settings and settings.show_sweet_spot) ..
                  " trade11=" .. DebugValue(trade) .. " item10=" .. DebugValue(item) ..
                  " itemID=" .. DebugValue(id))
        end

        if ranged == false then
            print("|cffffcc00WST Range branch:|r ranged=false; " ..
                  "closeFallback28yd=" .. DebugValue(IsCloseFallback()) ..
                  " mark=" .. DebugValue(mark))
        elseif ranged == true then
            print("|cffffcc00WST Range branch:|r ranged=true")
        else
            print("|cffffcc00WST Range branch:|r ranged=nil")
        end
    else
        print("|cffffcc00WST Range:|r main-hand=" .. DebugValue(NativeSwingInRange("MainHand")) ..
              " item5=" .. DebugValue(ItemRange(5)))
        local probes = CLASS_RANGE_PROBES[class]
        if not probes then
            print("|cffffcc00WST Range:|r no configured probes for this class")
        else
            for _, spell_name in ipairs(probes) do
                local known = HasSpellBookSpell(spell_name)
                local in_range = known and
                    SpellBookSpellInRange(spell_name) or nil
                local min_range, max_range, resolved =
                    GetSpellRangeInfo(spell_name)

                print("|cffffcc00WST Range probe:|r " ..
                      spell_name ..
                      " known=" .. DebugValue(known) ..
                      " inRange=" .. DebugValue(in_range) ..
                      " resolved=" .. DebugValue(resolved) ..
                      " min=" .. DebugValue(min_range) ..
                      " max=" .. DebugValue(max_range))
            end
        end
    end

    local band, key = addon_data.range.GetRangeBand()
    print("|cffffcc00WST Range:|r CURRENT RESULT = " ..
          DebugValue(band) .. " [" .. DebugValue(key) .. "]")
    print("|cff00ff00=====================================|r")
end

SLASH_WSTRANGEDEBUG1 = "/wstrangedebug"
SlashCmdList["WSTRANGEDEBUG"] = function()
    addon_data.range.DumpDebug()
end


addon_data.range.LoadSettings = function()
    -- Existing profiles created before the Range module will not necessarily
    -- have a physical range table yet, so create one explicitly.
    addon_data.db.profile.range = addon_data.db.profile.range or {}
    character_range_settings = addon_data.db.profile.range

    for setting, value in pairs(addon_data.range.default_settings) do
        if character_range_settings[setting] == nil then
            character_range_settings[setting] = value
        end
    end

    -- Range Check is opt-in for every class. Existing profiles that already
    -- have an explicit enabled/disabled value are left untouched.
    if character_range_settings.enabled == nil then
        character_range_settings.enabled = false
    end
end

addon_data.range.OnFrameDragStart = function()
    if not character_range_settings.is_locked then
        addon_data.range.frame:StartMoving()
    end
end

addon_data.range.OnFrameDragStop = function()
    local frame = addon_data.range.frame
    frame:StopMovingOrSizing()

    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end

    character_range_settings.point = point
    character_range_settings.rel_point = rel_point
    character_range_settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    character_range_settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)

    addon_data.range.UpdateVisualsOnSettingsChange()
    addon_data.range.UpdateConfigPanelValues()
end

addon_data.range.UpdateRange = function()
    local frame = addon_data.range.frame
    local settings = character_range_settings

    if not frame or not settings or not settings.enabled then
        if frame then frame:Hide() end
        return
    end

    local preview = addon_data.config.IsBarPreviewActive()
    if not preview and ((settings.hide_no_target and not UnitExists("target")) or
       (settings.hide_dead_target and UnitExists("target") and UnitIsDeadOrGhost("target"))) then
        frame:Hide()
        return
    end
    local text, key = addon_data.range.GetRangeBand()
    if not text then
        text = L["NO TARGET"]
        key = "unknown"
    end

    -- An unchanged default keeps dynamic labels (talent range and fallback probes).
    local override = settings["text_" .. key]
    if override ~= nil and override ~= addon_data.range.default_settings["text_" .. key] then
        text = override
    end
    frame:Show()
    addon_data.range.current_text = text
    addon_data.range.current_key = key

    local c = GetRangeColor(settings, key)
    frame.bar:SetVertexColor(c[1], c[2], c[3], c[4])

    if settings.show_text then
        frame.text:SetText(text)
        frame.text:Show()
    else
        frame.text:Hide()
    end

    if preview then
        frame.content:SetAlpha(1)
    elseif addon_data.core.in_combat then
        frame.content:SetAlpha(settings.in_combat_alpha)
    else
        frame.content:SetAlpha(settings.ooc_alpha)
    end
end

addon_data.range.OnUpdate = function(self, elapsed)
    addon_data.range.update_elapsed = addon_data.range.update_elapsed + elapsed
    if addon_data.range.update_elapsed < 0.10 then
        return
    end
    addon_data.range.update_elapsed = 0
    addon_data.range.UpdateRange()
end

addon_data.range.InitializeVisuals = function()
    local settings = character_range_settings

    addon_data.range.frame = CreateFrame(
        "Frame",
        addon_name .. "RangeFrame",
        UIParent
    )
    local frame = addon_data.range.frame

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.range.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.range.OnFrameDragStop)
    -- A separate driver continues polling even when the visible bar is hidden.
    addon_data.range.update_frame = CreateFrame("Frame", nil, UIParent)
    addon_data.range.update_frame:SetSize(1, 1)
    addon_data.range.update_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    addon_data.range.update_frame:SetScript("OnUpdate", addon_data.range.OnUpdate)
    addon_data.range.update_frame:Show()
    addon_data.range.update_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    addon_data.range.update_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    addon_data.range.update_frame:SetScript("OnEvent", function()
        addon_data.range.UpdateVisualsOnSettingsChange()
    end)

    -- Keep the public frame available for external fades; apply our opacity inside it.
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetAllPoints(frame)

    frame.backplane = CreateFrame(
        "Frame",
        addon_name .. "RangeBackdropFrame",
        frame.content,
        "BackdropTemplate"
    )
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")

    frame.bar = frame.content:CreateTexture(nil, "ARTWORK")
    frame.bar:SetAllPoints(frame)

    frame.text = frame.content:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")
    frame.text:SetJustifyV("MIDDLE")

    -- A FontString must have a font before SetText() is called. This is done
    -- here instead of relying on UpdateVisualsOnSettingsChange(), because that
    -- function returns early when Range Check is disabled.
    addon_data.config.ApplyBarFont(frame.text, settings)
    frame.text:SetTextColor(1, 1, 1, 1)

    addon_data.range.UpdateVisualsOnSettingsChange()

    if settings.enabled then
        -- Visible initial state so the enabled bar can be positioned even
        -- without a target.
        frame:Show()
        frame.text:SetText(L["NO TARGET"])
        local c = GetRangeColor(settings, "unknown")
        frame.bar:SetVertexColor(c[1], c[2], c[3], c[4])

        addon_data.range.UpdateRange()
    else
        frame:Hide()
    end
end

addon_data.range.UpdateVisualsOnSettingsChange = function()
    local frame = addon_data.range.frame
    local settings = character_range_settings

    if not frame or not settings then
        return
    end

    if not settings.enabled then
        frame:Hide()
        return
    end

    frame:EnableMouse(not settings.is_locked)
    frame:ClearAllPoints()
    frame:SetPoint(
        settings.point,
        UIParent,
        settings.rel_point,
        settings.x_offset,
        settings.y_offset
    )
    frame:SetSize(settings.width, settings.height)

    if settings.show_border then
        frame.backplane:SetBackdrop({
            bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background",
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = {left = 8, right = 8, top = 8, bottom = 8},
        })
    else
        frame.backplane:SetBackdrop({
            bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background",
            edgeFile = nil,
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 8, right = 8, top = 8, bottom = 8},
        })
    end

    frame.backplane:SetBackdropColor(0, 0, 0, settings.backplane_alpha)

    frame.bar:SetTexture(addon_data.config.GetBarTexture(settings))

    addon_data.config.ApplyBarFont(frame.text, settings)
    frame.text:SetTextColor(1, 1, 1, 1)

    addon_data.range.UpdateRange()
end

addon_data.range.UpdateConfigPanelValues = function()
    local panel = addon_data.range.config_frame
    local settings = character_range_settings

    if not panel or not settings then
        return
    end

    for _, field in ipairs({"hide_no_target", "hide_dead_target", "show_sweet_spot", "show_sniper_shot"}) do
        if panel[field .. "_checkbox"] then
            panel[field .. "_checkbox"]:SetChecked(settings[field])
        end
    end
    if panel.text_editboxes then
        for key, box in pairs(panel.text_editboxes) do
            local field = "text_" .. key
            local value = settings[field]
            if type(value) ~= "string" then
                value = addon_data.range.default_settings[field] or ""
                settings[field] = value
            end
            box:SetText(value)
            box:SetCursorPosition(0)
        end
    end
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.show_text_checkbox:SetChecked(settings.show_text)

    panel.width_editbox:SetText(tostring(settings.width))
    panel.width_editbox:SetCursorPosition(0)
    panel.height_editbox:SetText(tostring(settings.height))
    panel.height_editbox:SetCursorPosition(0)
    panel.fontsize_editbox:SetText(tostring(settings.fontsize))
    panel.fontsize_editbox:SetCursorPosition(0)
    panel.x_offset_editbox:SetText(tostring(settings.x_offset))
    panel.x_offset_editbox:SetCursorPosition(0)
    panel.y_offset_editbox:SetText(tostring(settings.y_offset))
    panel.y_offset_editbox:SetCursorPosition(0)

    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    if panel.in_combat_alpha_slider.editbox then
        panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    end
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    if panel.ooc_alpha_slider.editbox then
        panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    end
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    if panel.backplane_alpha_slider.editbox then
        panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
    end

    local color_pickers = {
        {"melee_color_picker", "melee"},
        {"deadzone_color_picker", "deadzone"},
        {"sweet_spot_color_picker", "sweet_spot"},
        {"close_color_picker", "close"},
        {"ranged_color_picker", "ranged"},
        {"sniper_shot_color_picker", "sniper_shot"},
        {"far_color_picker", "far"},
        {"out_color_picker", "out"},
        {"unknown_color_picker", "unknown"},
    }

    for _, entry in ipairs(color_pickers) do
        local picker = panel[entry[1]]
        local key = entry[2]
        if picker and picker.foreground then
            picker.foreground:SetColorTexture(
                settings[key .. "_r"],
                settings[key .. "_g"],
                settings[key .. "_b"],
                settings[key .. "_a"]
            )
        end
    end
end

addon_data.range.EnabledCheckBoxOnClick = function(self)
    character_range_settings.enabled = self:GetChecked()
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.ShowBorderCheckBoxOnClick = function(self)
    character_range_settings.show_border = self:GetChecked()
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.ShowTextCheckBoxOnClick = function(self)
    character_range_settings.show_text = self:GetChecked()
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.WidthEditBoxOnEnter = function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 then
        character_range_settings.width = value
        addon_data.range.UpdateVisualsOnSettingsChange()
    end
end

addon_data.range.HeightEditBoxOnEnter = function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 then
        character_range_settings.height = value
        addon_data.range.UpdateVisualsOnSettingsChange()
    end
end

addon_data.range.FontSizeEditBoxOnEnter = function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 then
        character_range_settings.fontsize = value
        addon_data.range.UpdateVisualsOnSettingsChange()
    end
end

addon_data.range.XOffsetEditBoxOnEnter = function(self)
    local value = tonumber(self:GetText())
    if value then
        character_range_settings.x_offset = value
        addon_data.range.UpdateVisualsOnSettingsChange()
    end
end

addon_data.range.YOffsetEditBoxOnEnter = function(self)
    local value = tonumber(self:GetText())
    if value then
        character_range_settings.y_offset = value
        addon_data.range.UpdateVisualsOnSettingsChange()
    end
end

addon_data.range.CombatAlphaOnValChange = function(self)
    character_range_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.OOCAlphaOnValChange = function(self)
    character_range_settings.ooc_alpha = tonumber(self:GetValue())
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.BackplaneAlphaOnValChange = function(self)
    character_range_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.range.UpdateVisualsOnSettingsChange()
end

addon_data.range.RangeColorPickerOnClick = function(self)
    local key = self.range_key
    addon_data.config.ShowColorPicker(
        character_range_settings,
        key,
        self.foreground,
        function()
            addon_data.range.UpdateRange()
        end
    )
end

addon_data.range.CreateConfigPanel = function(parent_panel, appearance_panel)
    addon_data.range.config_frame = CreateFrame(
        "Frame",
        addon_name .. "RangeConfigPanel",
        parent_panel
    )
    local panel = addon_data.range.config_frame
    local settings = character_range_settings

    panel.title_text = addon_data.config.TextFactory(panel, L["Range Check Settings"], 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)
    addon_data.config.SectionSummary(panel, "Hunters use shot range checks. Other classes use main-hand range, with item and ability checks as available.")

    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "RangeEnabledCheckBox",
        panel,
        L["Enable"],
        L["Enables the Range Check bar for this character."],
        addon_data.range.EnabledCheckBoxOnClick
    )
    panel.enabled_checkbox:SetScale(1)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -78)

    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "RangeShowBorderCheckBox",
        panel,
        L["Show border"],
        L["Shows the range bar border."],
        addon_data.range.ShowBorderCheckBoxOnClick
    )
    panel.show_border_checkbox:SetScale(1)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -126)


    panel.show_text_checkbox = addon_data.config.CheckBoxFactory(
        "RangeShowTextCheckBox",
        panel,
        L["Show range text"],
        L["Shows the estimated range band on the bar."],
        addon_data.range.ShowTextCheckBoxOnClick
    )
    panel.show_text_checkbox:SetScale(1)
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -102)

    panel.width_editbox = addon_data.config.EditBoxFactory(
        "RangeWidthEditBox", appearance_panel, L["Bar Width"], 75, 25,
        addon_data.range.WidthEditBoxOnEnter
    )

    panel.width_editbox:SetTextColor(1, 1, 1, 1)
    panel.width_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.height_editbox = addon_data.config.EditBoxFactory(
        "RangeHeightEditBox", appearance_panel, L["Bar Height"], 75, 25,
        addon_data.range.HeightEditBoxOnEnter
    )

    panel.height_editbox:SetTextColor(1, 1, 1, 1)
    panel.height_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "RangeFontSizeEditBox", appearance_panel, L["Font Size"], 75, 25,
        addon_data.range.FontSizeEditBoxOnEnter
    )

    panel.fontsize_editbox:SetTextColor(1, 1, 1, 1)
    panel.fontsize_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "RangeXOffsetEditBox", panel, L["X Offset"], 75, 25,
        addon_data.range.XOffsetEditBoxOnEnter
    )
    panel.x_offset_editbox:SetPoint("TOPLEFT", 220, -78)
    panel.x_offset_editbox:SetTextColor(1, 1, 1, 1)
    panel.x_offset_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "RangeYOffsetEditBox", panel, L["Y Offset"], 75, 25,
        addon_data.range.YOffsetEditBoxOnEnter
    )
    panel.y_offset_editbox:SetPoint("TOPLEFT", 304, -78)
    panel.y_offset_editbox:SetTextColor(1, 1, 1, 1)
    panel.y_offset_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")


    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "RangeCombatAlphaSlider",
        appearance_panel,
        L["In Combat"],
        0, 1, 0.05,
        addon_data.range.CombatAlphaOnValChange
    )

    if panel.in_combat_alpha_slider.editbox then
        panel.in_combat_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.in_combat_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "RangeOOCAlphaSlider",
        appearance_panel,
        L["Out of Combat"],
        0, 1, 0.05,
        addon_data.range.OOCAlphaOnValChange
    )

    if panel.ooc_alpha_slider.editbox then
        panel.ooc_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.ooc_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "RangeBackplaneAlphaSlider",
        appearance_panel,
        L["Background"],
        0, 1, 0.05,
        addon_data.range.BackplaneAlphaOnValChange
    )

    if panel.backplane_alpha_slider.editbox then
        panel.backplane_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.backplane_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    local function MakeRangeColorPicker(field, key, label)
        local picker = addon_data.config.color_picker_factory(
            field,
            appearance_panel,
            settings[key .. "_r"],
            settings[key .. "_g"],
            settings[key .. "_b"],
            settings[key .. "_a"],
            label,
            addon_data.range.RangeColorPickerOnClick
        )
        picker.range_key = key
        return picker
    end

    panel.melee_color_picker =
        MakeRangeColorPicker("RangeMeleeColor", "melee", L["0-5 Melee"])
    panel.deadzone_color_picker =
        MakeRangeColorPicker("RangeDeadzoneColor", "deadzone", L["5-8 Dead Zone"])
    panel.sweet_spot_color_picker =
        MakeRangeColorPicker("RangeSweetSpotColor", "sweet_spot", "Sweet Spot (8-11 yd)")
    panel.close_color_picker =
        MakeRangeColorPicker("RangeCloseColor", "close", L["8-15 Close"])

    panel.ranged_color_picker =
        MakeRangeColorPicker("RangeRangedColor", "ranged", L["Ranged (8-35 / 15-35)"])
    panel.sniper_shot_color_picker =
        MakeRangeColorPicker("RangeSniperShotColor", "sniper_shot", "Sniper Shot / Buff")
    panel.far_color_picker =
        MakeRangeColorPicker("RangeFarColor", "far", L["35-100 Far"])
    panel.out_color_picker =
        MakeRangeColorPicker("RangeOutColor", "out", L["Out of Range"])

    panel.unknown_color_picker =
        MakeRangeColorPicker("RangeUnknownColor", "unknown", L["No Target / Unknown"])

    panel.hide_no_target_checkbox = addon_data.config.CheckBoxFactory(
        "RangeHideNoTarget", panel, "Hide with no target", "Hide the range bar when no target is selected.",
        function(self) character_range_settings.hide_no_target = self:GetChecked(); addon_data.range.UpdateRange() end)
    panel.hide_no_target_checkbox:SetScale(1)
    panel.hide_no_target_checkbox:SetPoint("TOPLEFT", 10, -150)
    panel.hide_dead_target_checkbox = addon_data.config.CheckBoxFactory(
        "RangeHideDeadTarget", panel, "Hide with dead target", "Hide the range bar when the target is dead.",
        function(self) character_range_settings.hide_dead_target = self:GetChecked(); addon_data.range.UpdateRange() end)
    panel.hide_dead_target_checkbox:SetScale(1)
    panel.hide_dead_target_checkbox:SetPoint("TOPLEFT", 10, -174)

    panel.show_sweet_spot_checkbox = addon_data.config.CheckBoxFactory(
        "RangeShowSweetSpot", panel, "Show Hunter sweet spot (8-11 yd)",
        "Highlights the close edge of Auto Shot range. Uses a positive ~11 yd trade check or a positive 10 yd item check.",
        function(self)
            character_range_settings.show_sweet_spot = self:GetChecked()
            addon_data.range.UpdateRange()
        end)
    panel.show_sweet_spot_checkbox:SetScale(1)
    panel.show_sweet_spot_checkbox:SetPoint("TOPLEFT", 10, -198)

    local function RangeOption(field, name, tooltip, y)
        local box = addon_data.config.CheckBoxFactory("RangeOption" .. field, panel, name, tooltip,
            function(self)
                character_range_settings[field] = self:GetChecked()
                addon_data.range.UpdateRange()
            end)
        box:SetScale(1)
        box:SetPoint("TOPLEFT", 10, y)
        panel[field .. "_checkbox"] = box
    end
    RangeOption("show_sniper_shot", "Show Sniper Shot range", "Highlight Sniper Shot reach and its temporary range buff.", -222)

    panel.range_labels_heading = addon_data.config.TextFactory(panel, L["Range Labels"] or "Range Labels", 16)
    panel.range_labels_heading:SetPoint("TOPLEFT", 10, -264)
    panel.range_labels_heading:SetTextColor(1, 0.82, 0, 1)

    addon_data.config.SectionSummary(panel, "Edit the text shown for each range band.", -286, 376)

    panel.text_editboxes = {}
    local bands = {
        {"melee", "Melee"}, {"deadzone", "Dead zone"}, {"sweet_spot", "Sweet spot"}, {"close", "Close"},
        {"ranged", "Ranged"}, {"sniper_shot", "Sniper Shot"}, {"far", "Far"}, {"out", "Out of range"}, {"unknown", "No target / Unknown"}
    }
    for i, band in ipairs(bands) do
        local key = band[1]
        local box = addon_data.config.EditBoxFactory("RangeText" .. key, panel, band[2], 182, 25,
            function(self)
                character_range_settings["text_" .. key] = self:GetText()
                addon_data.range.UpdateRange()
            end)
        box:SetFont("Fonts/FRIZQT__.ttf", 11, "OUTLINE")
        box:SetTextInsets(4, 4, 0, 0)
        box:SetMaxLetters(120)
        -- Save only user edits; allow an intentionally blank label.
        box:SetScript("OnTextChanged", function(self, user_input)
            if user_input then
                character_range_settings["text_" .. key] = self:GetText()
                addon_data.range.UpdateRange()
            end
        end)
        box:SetPoint("TOPLEFT", 10 + ((i - 1) % 2) * 194, -328 - math.floor((i - 1) / 2) * 40)
        panel.text_editboxes[key] = box
    end
    panel:SetSize(620, 640)

    -- Settings canvas can create/show this panel after its initial construction.
    -- Refresh the values every time it becomes visible so the edit boxes and
    -- sliders always show the active profile values.
    panel:SetScript("OnShow", function()
        addon_data.range.UpdateConfigPanelValues()
    end)

    addon_data.range.UpdateConfigPanelValues()
    return panel
end

-- Recover an off-screen, transparent, or disabled range bar for positioning.
SLASH_WSTRANGESHOW1 = "/wstrangeshow"
SlashCmdList["WSTRANGESHOW"] = function()
    local settings = character_range_settings
    if not settings then return end
    settings.enabled = true
    settings.point, settings.rel_point = "CENTER", "CENTER"
    settings.x_offset, settings.y_offset = 0, -290
    settings.width = tonumber(settings.width) or 300
    settings.height = tonumber(settings.height) or 12
    if settings.width <= 0 then settings.width = 300 end
    if settings.height <= 0 then settings.height = 12 end
    settings.in_combat_alpha, settings.ooc_alpha = 1, 1
    settings.hide_no_target, settings.hide_dead_target = false, false
    addon_data.range.UpdateVisualsOnSettingsChange()
    addon_data.range.UpdateConfigPanelValues()
    print("WeaponSwingTimer: Range Check enabled and centered; target hiding disabled.")
end
