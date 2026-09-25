local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.range = {}

addon_data.range.default_settings = {
    enabled = false,
    width = 300,
    height = 12,
    fontsize = 10,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -290,
    in_combat_alpha = 1.0,
    ooc_alpha = 0.65,
    backplane_alpha = 0.5,
    is_locked = false,
    show_text = true,
    show_border = false,
    classic_bars = true,

    melee_r = 0.85, melee_g = 0.20, melee_b = 0.20, melee_a = 1.0,
    deadzone_r = 1.00, deadzone_g = 0.90, deadzone_b = 0.10, deadzone_a = 1.0,
    close_r = 0.95, close_g = 0.75, close_b = 0.10, close_a = 1.0,
    ranged_r = 0.20, ranged_g = 0.75, ranged_b = 0.20, ranged_a = 1.0,
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
                return NormalizeRangeResult(result)
            end
        end
    end

    -- Compatibility fallback for clients/builds where the spellbook API
    -- cannot resolve the item.
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

local function NativeRangedInRange()
    if C_SwingTimer and C_SwingTimer.IsTargetWithinSwingRange and
       Enum and Enum.PlayerSwingType and Enum.PlayerSwingType.Ranged then
        local ok, result = pcall(
            C_SwingTimer.IsTargetWithinSwingRange,
            Enum.PlayerSwingType.Ranged
        )
        if ok and result ~= nil then
            return result
        end
    end

    return SpellBookSpellInRange("Auto Shot")
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
    if ok4 and (result4 == true or result4 == 1) then
        return true
    end

    local ok1, result1 = pcall(CheckInteractDistance, "target", 1)
    if ok1 and (result1 == true or result1 == 1) then
        return true
    end

    return false
end

local function GetAutoShotMaxRange()
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, AUTO_SHOT_ID)
        if ok and type(info) == "table" then
            local max_range = tonumber(info.maxRange)
            if max_range and max_range > 0 then
                return math.floor(max_range + 0.5)
            end
        end
    end
    return 35
end

local function GetSpellRangeInfo(spell_identifier)
    if not C_Spell or not C_Spell.GetSpellInfo then
        return nil, nil, nil
    end

    local ok, info = pcall(C_Spell.GetSpellInfo, spell_identifier)
    if not ok or type(info) ~= "table" then
        return nil, nil, nil
    end

    return tonumber(info.minRange), tonumber(info.maxRange), info.name
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

    -- Auto Shot has an 8 yd minimum. If we're not in melee, Auto Shot is
    -- unavailable, and Scatter is still in range, this is the dead zone.
    if ranged == false and scatter == true then
        return L["5-8 yd  •  DEAD ZONE"], "deadzone"
    end

    if ranged == true then
        local max_range = GetAutoShotMaxRange()

        if HasSpellBookSpell("Scatter Shot") then
            if scatter == true then
                return L["8-15 yd"], "close"
            end
            return string.format(L["15-%d yd"], max_range), "ranged"
        end

        -- Without Scatter Shot there is no reliable 15-yard breakpoint.
        return string.format(L["8-%d yd"], max_range), "ranged"
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

        if mark == true then
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

    local text, key = addon_data.range.GetRangeBand()
    if not text then
        text = L["NO TARGET"]
        key = "unknown"
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

    if addon_data.core.in_combat then
        frame:SetAlpha(settings.in_combat_alpha)
    else
        frame:SetAlpha(settings.ooc_alpha)
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
    frame:SetScript("OnUpdate", addon_data.range.OnUpdate)

    frame.backplane = CreateFrame(
        "Frame",
        addon_name .. "RangeBackdropFrame",
        frame,
        "BackdropTemplate"
    )
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")

    frame.bar = frame:CreateTexture(nil, "ARTWORK")
    frame.bar:SetAllPoints(frame)

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")
    frame.text:SetJustifyV("MIDDLE")

    -- A FontString must have a font before SetText() is called. This is done
    -- here instead of relying on UpdateVisualsOnSettingsChange(), because that
    -- function returns early when Range Check is disabled.
    frame.text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize or 10)
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

    if settings.classic_bars then
        frame.bar:SetTexture("Interface/AddOns/WeaponSwingTimer/Images/Bar")
    else
        frame.bar:SetTexture("Interface/AddOns/WeaponSwingTimer/Images/Background")
    end

    frame.text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.text:SetTextColor(1, 1, 1, 1)

    addon_data.range.UpdateRange()
end

addon_data.range.UpdateConfigPanelValues = function()
    local panel = addon_data.range.config_frame
    local settings = character_range_settings

    if not panel or not settings then
        return
    end

    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
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
        {"close_color_picker", "close"},
        {"ranged_color_picker", "ranged"},
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

addon_data.range.ClassicBarsCheckBoxOnClick = function(self)
    character_range_settings.classic_bars = self:GetChecked()
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

addon_data.range.CreateConfigPanel = function(parent_panel)
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

    panel.disclaimer_text = addon_data.config.TextFactory(
        panel,
        L["Hunter range bands are the primary tested implementation. Other classes use experimental ability-range checks and need testing."],
        11
    )
    panel.disclaimer_text:SetPoint("TOPLEFT", 10, -38)
    panel.disclaimer_text:SetWidth(555)
    panel.disclaimer_text:SetJustifyH("LEFT")
    panel.disclaimer_text:SetTextColor(0.95, 0.60, 0.25, 1)

    panel.general_text = addon_data.config.TextFactory(panel, L["General Settings"], 16)
    panel.general_text:SetPoint("TOPLEFT", 10, -78)
    panel.general_text:SetTextColor(1, 0.82, 0, 1)

    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "RangeEnabledCheckBox",
        panel,
        L["Enable"],
        L["Enables the Range Check bar for this character."],
        addon_data.range.EnabledCheckBoxOnClick
    )
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -105)

    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "RangeShowBorderCheckBox",
        panel,
        L["Show border"],
        L["Shows the range bar border."],
        addon_data.range.ShowBorderCheckBoxOnClick
    )
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -155)

    panel.classic_bars_checkbox = addon_data.config.CheckBoxFactory(
        "RangeClassicBarsCheckBox",
        panel,
        L["Classic bar texture"],
        L["Uses the classic WeaponSwingTimer bar texture."],
        addon_data.range.ClassicBarsCheckBoxOnClick
    )
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -180)

    panel.show_text_checkbox = addon_data.config.CheckBoxFactory(
        "RangeShowTextCheckBox",
        panel,
        L["Show range text"],
        L["Shows the estimated range band on the bar."],
        addon_data.range.ShowTextCheckBoxOnClick
    )
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -130)

    panel.width_editbox = addon_data.config.EditBoxFactory(
        "RangeWidthEditBox", panel, L["Bar Width"], 75, 25,
        addon_data.range.WidthEditBoxOnEnter
    )
    panel.width_editbox:SetPoint("TOPLEFT", 205, -105)
    panel.width_editbox:SetTextColor(1, 1, 1, 1)
    panel.width_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.height_editbox = addon_data.config.EditBoxFactory(
        "RangeHeightEditBox", panel, L["Bar Height"], 75, 25,
        addon_data.range.HeightEditBoxOnEnter
    )
    panel.height_editbox:SetPoint("TOPLEFT", 300, -105)
    panel.height_editbox:SetTextColor(1, 1, 1, 1)
    panel.height_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "RangeFontSizeEditBox", panel, L["Font Size"], 75, 25,
        addon_data.range.FontSizeEditBoxOnEnter
    )
    panel.fontsize_editbox:SetPoint("TOPLEFT", 395, -105)
    panel.fontsize_editbox:SetTextColor(1, 1, 1, 1)
    panel.fontsize_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "RangeXOffsetEditBox", panel, L["X Offset"], 75, 25,
        addon_data.range.XOffsetEditBoxOnEnter
    )
    panel.x_offset_editbox:SetPoint("TOPLEFT", 205, -160)
    panel.x_offset_editbox:SetTextColor(1, 1, 1, 1)
    panel.x_offset_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "RangeYOffsetEditBox", panel, L["Y Offset"], 75, 25,
        addon_data.range.YOffsetEditBoxOnEnter
    )
    panel.y_offset_editbox:SetPoint("TOPLEFT", 300, -160)
    panel.y_offset_editbox:SetTextColor(1, 1, 1, 1)
    panel.y_offset_editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")

    panel.alpha_text = addon_data.config.TextFactory(panel, L["Alpha Settings"], 16)
    panel.alpha_text:SetPoint("TOPLEFT", 10, -225)
    panel.alpha_text:SetTextColor(1, 0.82, 0, 1)

    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "RangeCombatAlphaSlider",
        panel,
        L["In Combat"],
        0, 1, 0.05,
        addon_data.range.CombatAlphaOnValChange
    )
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 20, -262)
    if panel.in_combat_alpha_slider.editbox then
        panel.in_combat_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.in_combat_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "RangeOOCAlphaSlider",
        panel,
        L["Out of Combat"],
        0, 1, 0.05,
        addon_data.range.OOCAlphaOnValChange
    )
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 205, -262)
    if panel.ooc_alpha_slider.editbox then
        panel.ooc_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.ooc_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "RangeBackplaneAlphaSlider",
        panel,
        L["Background"],
        0, 1, 0.05,
        addon_data.range.BackplaneAlphaOnValChange
    )
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 390, -262)
    if panel.backplane_alpha_slider.editbox then
        panel.backplane_alpha_slider.editbox:SetTextColor(1, 1, 1, 1)
        panel.backplane_alpha_slider.editbox:SetFont("Fonts/FRIZQT__.ttf", 12, "OUTLINE")
    end

    panel.colors_text = addon_data.config.TextFactory(panel, L["Range Colors"], 16)
    panel.colors_text:SetPoint("TOPLEFT", 10, -330)
    panel.colors_text:SetTextColor(1, 0.82, 0, 1)

    local function MakeRangeColorPicker(field, key, label, x, y)
        local picker = addon_data.config.color_picker_factory(
            field,
            panel,
            settings[key .. "_r"],
            settings[key .. "_g"],
            settings[key .. "_b"],
            settings[key .. "_a"],
            label,
            addon_data.range.RangeColorPickerOnClick
        )
        picker.range_key = key
        picker:SetPoint("TOPLEFT", x, y)
        return picker
    end

    panel.melee_color_picker =
        MakeRangeColorPicker("RangeMeleeColor", "melee", L["0-5 Melee"], 20, -365)
    panel.deadzone_color_picker =
        MakeRangeColorPicker("RangeDeadzoneColor", "deadzone", L["5-8 Dead Zone"], 300, -365)
    panel.close_color_picker =
        MakeRangeColorPicker("RangeCloseColor", "close", L["8-15 Close"], 20, -400)

    panel.ranged_color_picker =
        MakeRangeColorPicker("RangeRangedColor", "ranged", L["Ranged (8-35 / 15-35)"], 300, -400)
    panel.far_color_picker =
        MakeRangeColorPicker("RangeFarColor", "far", L["35-100 Far"], 20, -435)
    panel.out_color_picker =
        MakeRangeColorPicker("RangeOutColor", "out", L["Out of Range"], 300, -435)

    panel.unknown_color_picker =
        MakeRangeColorPicker("RangeUnknownColor", "unknown", L["No Target / Unknown"], 20, -470)

    panel.info = addon_data.config.TextFactory(
        panel,
        L["Hunter bands: 0-5 melee • 5-8 dead zone • 8-35 ranged • Scatter adds an 8-15 breakpoint • 35-100 far"],
        11
    )
    panel.info:SetPoint("TOPLEFT", 10, -510)
    panel.info:SetJustifyH("LEFT")

    panel:SetSize(620, 545)

    -- Settings canvas can create/show this panel after its initial construction.
    -- Refresh the values every time it becomes visible so the edit boxes and
    -- sliders always show the active profile values.
    panel:SetScript("OnShow", function()
        addon_data.range.UpdateConfigPanelValues()
    end)

    addon_data.range.UpdateConfigPanelValues()
    return panel
end
