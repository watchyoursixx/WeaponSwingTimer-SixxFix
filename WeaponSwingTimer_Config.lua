local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.config = {}

-- Preview is a session-only display override. Live timers keep running.
addon_data.config.IsBarPreviewActive = function()
    return addon_data.config.preview_bars and not addon_data.core.in_combat
end

addon_data.config.OnDefault = function()
    addon_data.core.RestoreAllDefaults()
    addon_data.config.UpdateConfigValues()
end

local media = {
    font = {
        {"friz", "Friz Quadrata", "Fonts/FRIZQT__.ttf"},
        {"arial", "Arial Narrow", "Fonts/ARIALN.ttf"},
        {"morpheus", "Morpheus", "Fonts/MORPHEUS.ttf"},
        {"skurri", "Skurri", "Fonts/skurri.ttf"},
    },
    statusbar = {
        {"classic", "Classic", "Interface/AddOns/WeaponSwingTimer/Images/Bar"},
        {"flat", "Flat", "Interface/AddOns/WeaponSwingTimer/Images/Background"},
        {"blizzard", "Blizzard", "Interface/TargetingFrame/UI-StatusBar"},
        {"solid", "Solid", "Interface/Buttons/WHITE8X8"},
    },
}

local function GetSharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

local function ResolveMedia(kind, key)
    if not key or key == "default" then return nil end
    for _, item in ipairs(media[kind]) do
        if item[1] == key then return item[3] end
    end
    local name = key:match("^shared:(.+)$")
    local shared = name and GetSharedMedia()
    return shared and shared:Fetch(kind, name, true) or nil
end

addon_data.config.ApplyBarFont = function(label, settings)
    local default_font = media.font[1][3]
    local path = ResolveMedia("font", settings.bar_font)
    local size = settings.fontsize or 10
    if path then
        local ok, applied = pcall(label.SetFont, label, path, size)
        if ok and applied then return end
    end
    label:SetFont(default_font, size)
end

addon_data.config.GetBarTexture = function(settings)
    return ResolveMedia("statusbar", settings.bar_texture)
        or (settings.classic_bars and media.statusbar[1][3] or media.statusbar[2][3])
end

local function MediaLabel(kind, key)
    if not key or key == "default" then return DEFAULT or "Default" end
    for _, item in ipairs(media[kind]) do
        if item[1] == key then return item[2] end
    end
    local name = key:match("^shared:(.+)$")
    if name then return ResolveMedia(kind, key) and name or name .. " (unavailable)" end
    return DEFAULT or "Default"
end

local function CreateMediaDropdown(panel, module, kind, title, x, y)
    local field = kind == "font" and "bar_font" or "bar_texture"
    local dropdown = CreateFrame("Frame", addon_name .. module .. field, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", x - 16, y)
    UIDropDownMenu_SetWidth(dropdown, 112)
    local label = addon_data.config.TextFactory(panel, title, 12)
    label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 18, 0)

    -- Resolve the settings table on each use so profile changes never leave stale references.
    local function GetSettings()
        return _G["character_" .. module .. "_settings"]
    end
    local function Refresh()
        UIDropDownMenu_SetText(dropdown, MediaLabel(kind, GetSettings()[field]))
    end
    local function AddChoice(key, text, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.checked = GetSettings()[field] == key
        info.func = function()
            GetSettings()[field] = key
            addon_data[module].UpdateVisualsOnSettingsChange()
            Refresh()
        end
        UIDropDownMenu_AddButton(info, level)
    end
    UIDropDownMenu_Initialize(dropdown, function(_, level, menuList)
        if level == 2 then
            for _, name in ipairs(menuList or {}) do AddChoice("shared:" .. name, name, level) end
            return
        end
        AddChoice("default", DEFAULT or "Default", level)
        for _, item in ipairs(media[kind]) do AddChoice(item[1], item[2], level) end

        local shared = GetSharedMedia()
        local names = shared and shared:List(kind)
        if not names then return end
        for first = 1, #names, 18 do
            local last = math.min(first + 17, #names)
            local group = {}
            for index = first, last do group[#group + 1] = names[index] end
            local info = UIDropDownMenu_CreateInfo()
            info.text = #names <= 18 and "Shared Media" or ("Shared Media " .. first .. "–" .. last)
            info.hasArrow = true
            info.notCheckable = true
            info.menuList = group
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return Refresh
end

addon_data.config.RefreshAppearance = function()
    local panel = addon_data.config.config_parent_panel
    local appearance = panel and panel.config_appearance_panel
    for _, refresh in ipairs(appearance and appearance.media_refreshers or {}) do refresh() end
end

local appearance_tabs = {
    {module = "player", label = "Player", title = "Player Swing Bar Settings", colors = {
        "main_color_picker", "main_text_color_picker", "off_color_picker",
        "off_text_color_picker", "queued_color_picker",
    }},
    {module = "target", label = "Target", title = "Target Swing Bar Settings", colors = {
        "main_color_picker", "main_text_color_picker", "off_color_picker", "off_text_color_picker",
    }},
    {module = "hunter", label = "Ranged", title = "Hunter & Wand Shot Bar Settings", colors = {
        "cooldown_color_picker", "autoshot_cast_color_picker",
    }},
    {module = "castbar", label = "Spell Bar", title = "Player Spell Bar Settings"},
    {module = "range", label = "Range Check", title = "Range Check Settings", colors = {
        "melee_color_picker", "deadzone_color_picker", "sweet_spot_color_picker", "close_color_picker",
        "ranged_color_picker", "sniper_shot_color_picker", "far_color_picker", "out_color_picker", "unknown_color_picker",
    }},
}

local function CreateAppearanceTabs(panel)
    local panes = {}
    local strip = CreateFrame("Frame", addon_name .. "AppearanceTabs", panel, "BackdropTemplate")
    strip:SetSize(598, 498)
    strip:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -69)
    strip:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    strip:SetBackdropColor(0.06, 0.06, 0.08, 0.55)
    strip:SetBackdropBorderColor(0.58, 0.58, 0.62, 0.9)
    local heading = addon_data.config.TextFactory(panel, panel.name, 20)
    heading:SetPoint("TOPLEFT", 16, -12)
    heading:SetTextColor(1, 0.9, 0, 1)

    local function SelectTab(selected)
        if CloseDropDownMenus then CloseDropDownMenus() end
        PanelTemplates_SetTab(strip, selected)
        for index, tab in ipairs(appearance_tabs) do
            panes[tab.module]:SetShown(index == selected)
        end
    end

    for index, tab in ipairs(appearance_tabs) do
        local module = tab.module
        local button = CreateFrame("Button", strip:GetName() .. "Tab" .. index, strip, "PanelTopTabButtonTemplate")
        button:SetID(index)
        button:SetPoint("BOTTOMLEFT", strip, "TOPLEFT", 6 + (index - 1) * 116, -3)
        button:SetText(L[tab.label] or tab.label)
        PanelTemplates_TabResize(button, 0, 112)
        button:SetScript("OnClick", function(self) SelectTab(self:GetID()) end)

        local pane = CreateFrame("Frame", nil, strip)
        pane:SetSize(574, 472)
        pane:SetPoint("TOPLEFT", strip, "TOPLEFT", 14, -14)
        panes[module] = pane
    end
    PanelTemplates_SetNumTabs(strip, #appearance_tabs)
    SelectTab(1)
    return panes
end

-- Draw samples from the active profile, without changing the in-game bars.
local function CreateBarPreview(pane, module, behavior)
    local melee = module == "player" or module == "target"
    local palette = behavior and module == "range"
    local preview_width = behavior and 220 or 259
    local preview = CreateFrame("Frame", nil, pane, "BackdropTemplate")
    preview:SetPoint("TOPLEFT", pane, "TOPLEFT", behavior and 396 or 301, behavior and -78 or -36)
    preview:SetWidth(preview_width)
    preview:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    preview:SetBackdropColor(0, 0, 0, 0.45)
    local title_text = palette and "Range Colors" or "Bar Preview"
    local title = addon_data.config.TextFactory(preview, L[title_text] or title_text, 16)
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetTextColor(1, 0.9, 0, 1)

    local status
    if behavior then
        status = addon_data.config.TextFactory(preview, "", 11)
        status:SetPoint("TOPLEFT", 12, -31)
        status:SetWidth(preview_width - 24)
        status:SetJustifyH("LEFT")
        status:SetWordWrap(false)
    end
    local samples = {}
    local function Sample(caption, label, color, text_color, fraction, mode)
        local header = addon_data.config.TextFactory(preview, caption, 12)
        local frame = CreateFrame("Frame", nil, preview, "BackdropTemplate")
        frame.fill = frame:CreateTexture(nil, "ARTWORK")
        frame.fill:SetPoint("TOPLEFT")
        if module == "hunter" then
            frame.cast = frame:CreateTexture(nil, "ARTWORK", nil, 1)
            frame.retry = frame:CreateTexture(nil, "ARTWORK", nil, 2)
        end
        frame.text = frame:CreateFontString(nil, "OVERLAY")
        frame.text:SetPoint("LEFT", 4, 0)
        frame.text:SetPoint("RIGHT", -4, 0)
        frame.text:SetWordWrap(false)
        if mode == "spell" then
            frame.latency = frame:CreateTexture(nil, "ARTWORK", nil, 1)
            frame.latency:SetPoint("LEFT")
            frame.latency:SetColorTexture(1, 0, 0, 0.75)
        end
        if melee then
            frame.text:SetJustifyH("LEFT")
            frame.timer = frame:CreateFontString(nil, "OVERLAY")
            frame.timer:SetPoint("RIGHT", -4, 0)
        end
        samples[#samples + 1] = {header = header, frame = frame, label = label, color = color,
            text_color = text_color, fraction = fraction, mode = mode}
    end

    if behavior and melee then
        Sample("Main-hand", "Main-Hand", "main", "main_text", 0.68, "swing")
        Sample("Off-hand", "Off-Hand", "off", "off_text", 0.45, "swing")
        if module == "player" then
            Sample("Queued Attack", "Queued Attack", "queued", "main_text", 0.68, "swing")
        end
    elseif behavior and module == "hunter" then
        Sample("", nil, "cooldown", nil, nil, "selected")
    elseif behavior and module == "castbar" then
        Sample("Multi-Shot", "Multi-Shot", {0.8, 0.64, 0, 1}, nil, 0.6, "spell")
        Sample("Aimed Shot", "Aimed Shot", {0.8, 0.64, 0, 1}, nil, 0.6, "spell")
        Sample("Steady Shot", "Steady Shot", {0.8, 0.64, 0, 1}, nil, 0.6, "spell")
        samples[1].option, samples[2].option, samples[3].option =
            "show_multishot_cast_bar", "show_aimedshot_cast_bar", "show_steadyshot_cast_bar"
    elseif palette then
        Sample("Melee", "0-5 yd", "melee", nil, 1)
        Sample("Dead Zone", "5-8 yd", "deadzone", nil, 1)
        Sample("Sweet Spot", "8-11 yd", "sweet_spot", nil, 1)
        Sample("Close", "8-15 yd", "close", nil, 1)
        Sample("Ranged", "8-35 yd", "ranged", nil, 1)
        Sample("Sniper Shot", "35-45 yd", "sniper_shot", nil, 1)
        Sample("Far", "35-100 yd", "far", nil, 1)
        Sample("Out of Range", "100+ yd", "out", nil, 1)
        Sample("No Target / Unknown", "NO TARGET", "unknown", nil, 1)
    elseif melee then
        Sample("Main-hand", "Main-Hand", "main", "main_text", 0.68)
        Sample("Off-hand", "Off-Hand", "off", "off_text", 0.45)
        if module == "player" then
            Sample("Queued Attack", "Queued Attack", "queued", "main_text", 0.68)
        end
    elseif module == "hunter" then
        Sample("YaHT", nil, "cooldown", nil, nil, "yaht")
        Sample("One Bar", nil, "cooldown", nil, nil, "one_bar")
    elseif module == "castbar" then
        Sample("Spell Cast", "Aimed Shot  0.8", {0.8, 0.64, 0, 1}, nil, 0.6)
    else
        Sample("Ranged", "8-35 yd", "ranged", nil, 1)
        Sample("Dead Zone", "5-8 yd", "deadzone", nil, 1)
        Sample("Sweet Spot", "8-11 yd", "sweet_spot", nil, 1)
        Sample("Sniper Shot", "35-45 yd", "sniper_shot", nil, 1)
    end

    local function Color(settings, key)
        if type(key) == "table" then return key[1], key[2], key[3], key[4] end
        if not key then return 1, 1, 1, 1 end
        return settings[key .. "_r"] or 1, settings[key .. "_g"] or 1,
            settings[key .. "_b"] or 1, settings[key .. "_a"] or 1
    end

    local cooldown, cast_time, retry_time = 1.8, 0.5, 0.5
    local function AnimateRanged(settings, sample, time, width, height)
        local frame = sample.frame
        local include_retry = settings.show_autoshot_delay_timer
        local delay = include_retry and retry_time or 0
        local normal_cycle = cooldown + cast_time
        local phase = time % (2 * normal_cycle + delay)
        -- Alternate a normal shot and a retry so both paths are visible.
        if phase < normal_cycle then
            delay = 0
        else
            phase = phase - normal_cycle
        end
        local cooldown_left = math.max(0, cooldown - phase)
        local retry_left = math.max(0, delay - math.max(0, phase - cooldown))
        local cast_left = math.max(0, cast_time - math.max(0, phase - cooldown - delay))
        if phase < cooldown then retry_left = 0 end
        local one_bar = sample.mode == "one_bar" or (sample.mode == "selected" and settings.one_bar)
        local anchor = one_bar and "LEFT" or "CENTER"
        local scale = width / (cooldown + cast_time)
        local white, red, orange
        if one_bar then
            white = width - (cooldown_left + cast_left) * scale
            red = cast_left * scale
            orange = retry_left * scale
        else
            white = width * cooldown_left / cooldown
            red = width * (1 - cast_left / cast_time)
            orange = width * retry_left / retry_time
        end

        local function Segment(region, point, segment_width, x)
            region:ClearAllPoints()
            region:SetPoint(point, frame, point, x or 0, 0)
            region:SetSize(math.max(0.001, segment_width), height)
            region:SetShown(segment_width > 0.001)
        end

        Segment(frame.fill, anchor, white)
        Segment(frame.cast, one_bar and "RIGHT" or "CENTER", red)
        Segment(frame.retry, one_bar and "RIGHT" or "CENTER", orange, one_bar and -cast_time * scale or 0)
        frame.text:SetText(string.format("%.1f", cooldown_left + retry_left + cast_left))
    end

    local function AnimateSwing(settings, sample, time, width, height)
        local duration = sample.color == "off" and 1.9 or 2.5
        local elapsed = time % duration
        local fraction = elapsed / duration
        if settings.fill_empty == false then fraction = 1 - fraction end
        sample.frame.fill:SetSize(math.max(0.001, width * fraction), height)
        sample.frame.timer:SetText(string.format("%.1f", duration - elapsed))
    end

    local function AnimateSpell(settings, sample, time, width, height)
        local duration = sample.option == "show_multishot_cast_bar" and 0.5 or 2
        local elapsed = time % duration
        sample.frame.fill:SetSize(math.max(0.001, width * elapsed / duration), height)
        sample.frame.latency:SetSize(width * 0.12, height)
        sample.frame.latency:SetShown(settings.show_latency_bars == true)
    end

    local width, height, time = 0, 0, 0
    local function Refresh()
        local settings = _G["character_" .. module .. "_settings"]
        width = math.max(12, math.min(preview_width - 24, tonumber(settings.width) or 300))
        height = math.max(6, math.min(behavior and 20 or 46, tonumber(settings.height) or 12))
        local row_height = behavior and math.max(35, height + 20) or math.max(58, height + 26)
        local top = behavior and 48 or 42
        local texture = addon_data.config.GetBarTexture(settings)
        local row = 0
        local enabled = settings.enabled ~= false
        local message
        for _, sample in ipairs(samples) do
            local frame = sample.frame
            local visible = not behavior or palette or (enabled and
                (not sample.option or settings[sample.option]) and
                (sample.color ~= "off" or settings.show_offhand ~= false))
            frame:SetShown(visible)
            local show_header = sample.mode ~= "selected"
            sample.header:SetShown(visible and show_header)
            if visible then
                local y = -top - row * row_height
                if show_header then sample.header:SetPoint("TOPLEFT", preview, "TOPLEFT", 12, y) end
                frame:SetPoint("TOPLEFT", preview, "TOPLEFT", 12, y - (show_header and 16 or 0))
                row = row + 1
            end
            frame:SetSize(width, height)
            frame:SetAlpha(palette and 1 or (settings.in_combat_alpha or 1))
            local show_border = not not settings.show_border
            if frame.preview_border ~= show_border then
                frame.preview_border = show_border
                local images = "Interface/AddOns/WeaponSwingTimer/Images/"
                frame:SetBackdrop({bgFile = images .. "Background", edgeFile = show_border and images .. "Border" or nil,
                    edgeSize = 8})
            end
            frame:SetBackdropColor(0, 0, 0, settings.backplane_alpha or 0.5)
            frame.fill:SetTexture(texture)
            frame.fill:SetVertexColor(Color(settings, sample.color))
            addon_data.config.ApplyBarFont(frame.text, settings)
            frame.text:SetTextColor(Color(settings, sample.text_color))
            if module == "hunter" then
                frame.cast:SetTexture(texture)
                frame.cast:SetVertexColor(Color(settings, "auto_cast"))
                frame.retry:SetTexture((not settings.bar_texture or settings.bar_texture == "default") and
                    "Interface/Buttons/WHITE8X8" or texture)
                frame.retry:SetVertexColor(1, 0.5, 0, 1)
                frame.text:SetJustifyH("RIGHT")
                frame.text:SetShown(settings.show_text ~= false)
                AnimateRanged(settings, sample, time, width, height)
            else
                local label, fraction = sample.label, sample.fraction
                if module == "range" then
                    label = settings["text_" .. sample.color] or label
                elseif melee then
                    if settings.fill_empty == false then fraction = 1 - fraction end
                    if sample.color == "queued" and settings.show_queued_attack_text == false then label = "Main-Hand" end
                    addon_data.config.ApplyBarFont(frame.timer, settings)
                    frame.timer:SetTextColor(Color(settings, sample.text_color))
                    frame.timer:SetText(sample.color == "off" and "1.1" or "0.8")
                    frame.timer:SetShown(settings.show_right_text ~= false)
                end
                frame.fill:SetSize(math.max(0.001, width * fraction), height)
                frame.text:SetText(L[label] or label)
                local text_setting = frame.timer and "show_left_text" or
                    (module == "castbar" and "show_cast_text" or "show_text")
                frame.text:SetShown(settings[text_setting] ~= false)
                if sample.mode == "swing" then AnimateSwing(settings, sample, time, width, height) end
                if sample.mode == "spell" then AnimateSpell(settings, sample, time, width, height) end
            end
        end
        if behavior then
            if not enabled then
                message = palette and "Range bar disabled in game" or "Bar disabled"
            elseif melee then
                message = settings.fill_empty == false and "Empty" or "Fill"
            elseif module == "hunter" then
                message = settings.one_bar and "One Bar" or "YaHT"
            elseif palette then
                if settings.hide_no_target and settings.hide_dead_target then
                    message = "Hides: no target or dead target"
                elseif settings.hide_no_target then
                    message = "Hides: no target"
                elseif settings.hide_dead_target then
                    message = "Hides: dead target"
                else
                    message = "All range bands"
                end
            elseif row == 0 then
                message = "No spell bars selected"
            else
                message = settings.show_latency_bars and "Latency shown in red" or "Selected spells"
            end
            status:SetText(L[message] or message)
            local header_height = module == "hunter" and 0 or 16
            preview:SetHeight(row == 0 and 54 or top + (row - 1) * row_height + header_height + height + 11)
        else
            preview:SetHeight(math.max(242, top + (#samples - 1) * row_height + 19 + height + 15))
        end
    end
    -- Only visible panels update. Keep animation smooth and refresh styling separately.
    local elapsed = 0
    preview:SetScript("OnShow", function()
        time, elapsed = 0, 0
        Refresh()
    end)
    preview:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        time = time + dt
        if elapsed >= 0.10 then
            elapsed = 0
            Refresh()
        elseif module == "hunter" or (behavior and (melee or module == "castbar")) then
            local settings = _G["character_" .. module .. "_settings"]
            for _, sample in ipairs(samples) do
                if sample.mode == "swing" then
                    AnimateSwing(settings, sample, time, width, height)
                elseif sample.mode == "spell" then
                    AnimateSpell(settings, sample, time, width, height)
                elseif module == "hunter" then
                    AnimateRanged(settings, sample, time, width, height)
                end
            end
        end
    end)
    Refresh()
end

local function LayoutAppearancePanel(panel, panes)
    panel.media_refreshers = {}
    for _, tab in ipairs(appearance_tabs) do
        local module = tab.module
        local pane = panes[module]
        local source = addon_data[module].config_frame
        local function Heading(text, y)
            local title = addon_data.config.TextFactory(pane, text, 16)
            title:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, y)
            title:SetTextColor(1, 0.9, 0, 1)
        end
        local function Place(control, x, y)
            control:ClearAllPoints()
            control:SetPoint("TOPLEFT", pane, "TOPLEFT", x, y)
        end

        Heading(L[tab.title] or tab.title, 0)
        Place(source.width_editbox, 2, -42)
        Place(source.height_editbox, 86, -42)
        Place(source.fontsize_editbox, 170, -42)
        Place(source.in_combat_alpha_slider, 4, -145)
        if source.ooc_alpha_slider then Place(source.ooc_alpha_slider, 4, -185) end
        Place(source.backplane_alpha_slider, 4, source.ooc_alpha_slider and -225 or -185)
        CreateBarPreview(pane, module)
        local refresh = panel.media_refreshers
        refresh[#refresh + 1] = CreateMediaDropdown(pane, module, "font", L["Font"] or "Font", 2, -88)
        refresh[#refresh + 1] = CreateMediaDropdown(pane, module, "statusbar", L["Bar Texture"] or "Bar Texture", 162, -88)

        if tab.colors then
            Heading(module == "range" and (L["Range Colors"] or "Range Colors") or (L["Colors"] or "Colors"), -262)
            for index, field in ipairs(tab.colors) do
                Place(source[field], 4, -289 - (index - 1) * (module == "range" and 18 or 21))
            end
        end
    end
end

addon_data.config.InitializeVisuals = function()

    -- Add the parent panel
    addon_data.config.config_parent_panel = CreateFrame("Frame", "MyFrame", UIParent)
    local panel = addon_data.config.config_parent_panel
    panel:SetSize(1, 1)
    panel.global_panel = addon_data.config.CreateConfigPanel(panel)
    panel.global_panel:SetPoint('TOPLEFT', 10, -10)
    panel.global_panel:SetSize(1, 1)

    panel.logo = panel:CreateTexture(nil, 'ARTWORK')	
    panel.logo:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/LandingPage')	
    panel.logo:SetSize(1024, 1024)	
    panel.logo:SetPoint('TOPLEFT', 5, -10)

    panel.name = "WeaponSwingTimer"
    panel.default = addon_data.config.OnDefault
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    addon_data.config.settingsCategoryID = category:GetID()
    
    local appearance = CreateFrame("Frame", nil, panel)
    appearance:SetSize(620, 576)
    appearance.name = L["Appearance"] or "Appearance"
    appearance.parent = panel.name
    appearance.default = addon_data.config.OnDefault
    panel.config_appearance_panel = appearance
    local appearance_panes = CreateAppearanceTabs(appearance)

    -- Add the melee panel
    panel.config_melee_panel = CreateFrame("Frame", nil, panel)
    panel.config_melee_panel:SetSize(620, 520)
    panel.config_melee_panel.player_panel = addon_data.player.CreateConfigPanel(panel.config_melee_panel, appearance_panes.player)
    panel.config_melee_panel.player_panel:SetPoint('TOPLEFT', 0, 0)
    panel.config_melee_panel.player_panel:SetSize(620, 270)
    panel.config_melee_panel.target_panel = addon_data.target.CreateConfigPanel(panel.config_melee_panel, appearance_panes.target)
    panel.config_melee_panel.target_panel:SetPoint('TOPLEFT', 0, -270)
    panel.config_melee_panel.target_panel:SetSize(620, 250)
    CreateBarPreview(panel.config_melee_panel.player_panel, "player", true)
    CreateBarPreview(panel.config_melee_panel.target_panel, "target", true)
    panel.config_melee_panel.name = L["Melee Settings"]
    panel.config_melee_panel.parent = panel.name
    panel.config_melee_panel.default = addon_data.config.OnDefault
    Settings.RegisterCanvasLayoutSubcategory(category, panel.config_melee_panel, panel.config_melee_panel.name)
    
    -- Add the hunter panel
    panel.config_hunter_panel = CreateFrame("Frame", nil, panel)
    panel.config_hunter_panel:SetSize(620, 1)
    panel.config_hunter_panel.hunter_panel = addon_data.hunter.CreateConfigPanel(panel.config_hunter_panel, appearance_panes.hunter)
    local hunter_panel_height = 214
    panel.config_hunter_panel.hunter_panel:SetSize(620, hunter_panel_height)
    panel.config_hunter_panel.hunter_panel:SetPoint('TOPLEFT', 0, 0)
    
    panel.config_hunter_panel.castbar_panel = addon_data.castbar.CreateConfigPanel(panel.config_hunter_panel, appearance_panes.castbar)	
    panel.config_hunter_panel.castbar_panel:SetSize(620, 260)
    local castbar_panel_position = - 10 - hunter_panel_height
    panel.config_hunter_panel.castbar_panel:SetPoint("TOPLEFT",0, castbar_panel_position)

    CreateBarPreview(panel.config_hunter_panel.hunter_panel, "hunter", true)
    CreateBarPreview(panel.config_hunter_panel.castbar_panel, "castbar", true)

    local totalHeight = panel.config_hunter_panel.hunter_panel:GetHeight() + panel.config_hunter_panel.castbar_panel:GetHeight() + 30
    panel.config_hunter_panel:SetHeight(totalHeight)

    panel.config_hunter_panel.name = L["Ranged Settings"]
    panel.config_hunter_panel.parent = panel.name
    panel.config_hunter_panel.default = addon_data.config.OnDefault
    Settings.RegisterCanvasLayoutSubcategory(category, panel.config_hunter_panel, panel.config_hunter_panel.name)

    -- Add the range finder panel
    panel.config_range_panel = CreateFrame("Frame", nil, panel)
    panel.config_range_panel:SetSize(620, 660)

    panel.config_range_panel.range_panel =
        addon_data.range.CreateConfigPanel(panel.config_range_panel, appearance_panes.range)
    panel.config_range_panel.range_panel:SetPoint("TOPLEFT", 0, 0)
    panel.config_range_panel.range_panel:SetSize(620, 640)

    CreateBarPreview(panel.config_range_panel.range_panel, "range", true)
    panel.config_range_panel.name = L["Range Check Settings"]
    panel.config_range_panel.parent = panel.name
    panel.config_range_panel.default = addon_data.config.OnDefault

    Settings.RegisterCanvasLayoutSubcategory(
        category,
        panel.config_range_panel,
        panel.config_range_panel.name
    )

    LayoutAppearancePanel(appearance, appearance_panes)
    appearance:SetScript("OnShow", addon_data.config.RefreshAppearance)
    addon_data.config.RefreshAppearance()
    Settings.RegisterCanvasLayoutSubcategory(category, appearance, appearance.name)

    -- Add the profiles panel
    panel.config_profiles_panel = CreateFrame("Frame", nil, panel)
    panel.config_profiles_panel:SetSize(1, 1)
    panel.config_profiles_panel.config_profiles_panel = addon_data.config.CreateProfilesPanel(panel.config_profiles_panel)
    panel.config_profiles_panel.name = L["Profiles"]
    panel.config_profiles_panel.parent = panel.name
    panel.config_profiles_panel.default = addon_data.config.OnDefault
    Settings.RegisterCanvasLayoutSubcategory(category, panel.config_profiles_panel, panel.config_profiles_panel.name)

end

addon_data.config.TextFactory = function(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    text_obj:SetFont("Fonts/FRIZQT__.ttf", size)
    text_obj:SetJustifyV("MIDDLE")
    text_obj:SetJustifyH("CENTER")
    text_obj:SetText(text)
    return text_obj
end

addon_data.config.SectionSummary = function(panel, text, y, width)
    local summary = addon_data.config.TextFactory(panel, L[text] or text, 11)
    summary:SetPoint("TOPLEFT", 10, y or -38)
    summary:SetWidth(width or 590)
    summary:SetJustifyH("LEFT")
    summary:SetTextColor(0.95, 0.60, 0.25, 1)
    return summary
end

addon_data.config.CheckBoxFactory = function(g_name, parent, checkbtn_text, tooltip_text, on_click_func)
    local checkbox = CreateFrame("CheckButton", addon_name .. g_name, parent, "ChatConfigCheckButtonTemplate")
    local label = getglobal(checkbox:GetName() .. "Text")
    label:ClearAllPoints()
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetJustifyH("LEFT")
    -- Older translations used leading spaces to position some captions.
    label:SetText((checkbtn_text or ""):match("^%s*(.-)%s*$"))
    checkbox.tooltip = tooltip_text
    checkbox:SetScript("OnClick", function(self)
        on_click_func(self)
    end)
    checkbox:SetScale(1)
    return checkbox
end

addon_data.config.EditBoxFactory = function(g_name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", addon_name .. g_name, parent, "BackdropTemplate")
    edit_box_obj.title_text = addon_data.config.TextFactory(edit_box_obj, title, 12)
    edit_box_obj.title_text:SetPoint("TOP", 0, 12)
    edit_box_obj:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 26,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4}
    })
    edit_box_obj:SetBackdropColor(0,0,0,1)
    edit_box_obj:SetSize(w, h)
    edit_box_obj:SetMultiLine(false)
    edit_box_obj:SetAutoFocus(false)
    edit_box_obj:SetMaxLetters(4)
    edit_box_obj:SetJustifyH("CENTER")
	edit_box_obj:SetJustifyV("MIDDLE")
    edit_box_obj:SetFontObject(GameFontNormal)
    edit_box_obj:SetScript("OnEnterPressed", function(self)
        enter_func(self)
        self:ClearFocus()
    end)
    edit_box_obj:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= "" then
            enter_func(self)
        end
    end)
    edit_box_obj:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit_box_obj
end

addon_data.config.SliderFactory = function(g_name, parent, title, min_val, max_val, val_step, func)
    local slider = CreateFrame("Slider", addon_name .. g_name, parent, "OptionsSliderTemplate")
    local editbox = CreateFrame("EditBox", "$parentEditBox", slider, "InputBoxTemplate")
    -- force slider to be set size, odd cases where it was missing
    slider:SetSize(120, 18)
    slider:SetMinMaxValues(min_val, max_val)
    slider:SetValueStep(val_step)
    slider:SetObeyStepOnDrag(true)
    editbox:SetSize(45,30)
    editbox:ClearAllPoints()
    editbox:SetPoint("LEFT", slider, "RIGHT", 15, 0)
    editbox:SetText(slider:GetValue())
    editbox:SetAutoFocus(false)
    slider:SetScript("OnValueChanged", function(self)
        editbox:SetText(tostring(addon_data.utils.SimpleRound(self:GetValue(), val_step)))
        func(self)
    end)

    -- force slider background to be set, odd cases where it was missing
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
    bg:SetPoint("LEFT", slider, "LEFT", 4, 0)
    bg:SetPoint("RIGHT", slider, "RIGHT", -4, 0)
    bg:SetHeight(6)

    -- force slider text to be set, odd cases where they were missing
    local name = slider:GetName()
    _G[name .. "Text"]:SetText(title)
    _G[name .. "Low"]:SetText(tostring(min_val))
    _G[name .. "High"]:SetText(tostring(max_val))

    editbox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText())
        if val then
            self:GetParent():SetValue(val)
        end
    end)
        editbox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then
            self:GetParent():SetValue(val)
            self:ClearFocus()
        end
    end)
    slider.editbox = editbox
    return slider
end

addon_data.config.color_picker_factory = function(g_name, parent, r, g, b, a, text, on_click_func)
    local color_picker = CreateFrame('Button', addon_name .. g_name, parent)
    color_picker:SetSize(15, 15)
    color_picker.normal = color_picker:CreateTexture(nil, 'BACKGROUND')
    color_picker.normal:SetColorTexture(1, 1, 1, 1)
    color_picker.normal:SetPoint('TOPLEFT', -1, 1)
    color_picker.normal:SetPoint('BOTTOMRIGHT', 1, -1)
    color_picker.foreground = color_picker:CreateTexture(nil, 'ARTWORK')
    color_picker.foreground:SetColorTexture(r, g, b, a)
    color_picker.foreground:SetAllPoints()
    color_picker:SetNormalTexture(color_picker.foreground)
    color_picker:SetScript('OnClick', on_click_func)
    color_picker.text = addon_data.config.TextFactory(color_picker, text, 12)
    color_picker.text:SetPoint('LEFT', 25, 0)
    return color_picker
end

addon_data.config.ShowColorPicker = function(settings, name, foreground_texture, on_change)
    local picker = ColorPickerFrame
    local start_r = settings[name .. "_r"]
    local start_g = settings[name .. "_g"]
    local start_b = settings[name .. "_b"]
    local start_a = settings[name .. "_a"] or 1
    local direct_alpha = type(picker.GetColorAlpha) == "function"
    local last_alpha = start_a

    local function WriteColor(r, g, b, a)
        settings[name .. "_r"] = r
        settings[name .. "_g"] = g
        settings[name .. "_b"] = b
        settings[name .. "_a"] = a
        foreground_texture:SetColorTexture(r, g, b, a)
        if on_change then on_change(r, g, b, a) end
    end

    local function Apply()
        local r, g, b = picker:GetColorRGB()
        local alpha
        if direct_alpha then
            alpha = picker:GetColorAlpha()
        elseif OpacitySliderFrame then
            local transparency = OpacitySliderFrame:GetValue()
            if type(transparency) == "number" then alpha = 1 - transparency end
        end
        -- The old picker.opacity field is the opening value, not the live slider.
        if type(alpha) == "number" and alpha >= 0 and alpha <= 1 then
            last_alpha = alpha
        end
        WriteColor(r, g, b, last_alpha)
    end

    picker:SetupColorPickerAndShow({
        r = start_r,
        g = start_g,
        b = start_b,
        hasOpacity = true,
        opacity = direct_alpha and start_a or (1 - start_a),
        swatchFunc = Apply,
        opacityFunc = Apply,
        cancelFunc = function()
            WriteColor(start_r, start_g, start_b, start_a)
        end,
    })
end

addon_data.config.UpdateConfigValues = function()
    local panel = addon_data.config.config_frame
    local settings = character_player_settings
    local settings_core = character_core_settings

    panel.is_locked_checkbox:SetChecked(settings.is_locked)
	panel.welcome_checkbox:SetChecked(settings_core.welcome_message)
end

addon_data.config.IsLockedCheckBoxOnClick = function(self)
    character_player_settings.is_locked = self:GetChecked()
    character_target_settings.is_locked = self:GetChecked()
    character_hunter_settings.is_locked = self:GetChecked()
    character_range_settings.is_locked = self:GetChecked()
    character_castbar_settings.is_locked = self:GetChecked()
    addon_data.player.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.target.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.hunter.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.range.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.castbar.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

addon_data.config.WelcomeCheckBoxOnClick = function(self)
	character_core_settings.welcome_message = self:GetChecked()
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

addon_data.config.CreateConfigPanel = function(parent_panel)
    addon_data.config.config_frame = CreateFrame("Frame", addon_name .. "GlobalConfigPanel", parent_panel)
    local panel = addon_data.config.config_frame
    local settings = character_player_settings
    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L["Global Bar Settings"], 20)
    panel.title_text:SetPoint("TOPLEFT", 0, 0)
    panel.title_text:SetTextColor(1, 0.9, 0, 1)
    
    -- Is Locked Checkbox
    panel.is_locked_checkbox = addon_data.config.CheckBoxFactory(
        "IsLockedCheckBox",
        panel,
        L[" Lock All Bars"],
        L["Locks all of the swing bar frames, preventing them from being dragged."],
        addon_data.config.IsLockedCheckBoxOnClick)
    panel.is_locked_checkbox:SetPoint("TOPLEFT", 0, -30)
	    -- Is Locked Checkbox
    panel.welcome_checkbox = addon_data.config.CheckBoxFactory(
        "WelcomeCheckBox",
        panel,
        L[" Welcome Message"],
        L["Displays the welcome message upon login/reload. Uncheck to disable."],
        addon_data.config.WelcomeCheckBoxOnClick)
    panel.welcome_checkbox:SetPoint("TOPLEFT", 0, -80)
    
    panel.preview_bars_checkbox = addon_data.config.CheckBoxFactory(
        "PreviewBarsCheckBox",
        panel,
        " Preview Bars",
        "Show enabled bars with sample values outside combat. Unlock the bars to move them.",
        function(self)
            addon_data.config.preview_bars = self:GetChecked()
        end)
    panel.preview_bars_checkbox:SetPoint("TOPLEFT", 0, -130)

    -- Return the final panel
    addon_data.config.UpdateConfigValues()
    return panel
end

addon_data.config.CreateProfilesPanel = function(parent)
    local panel = parent

    panel.title = addon_data.config.TextFactory(panel, "Profiles", 20)
    panel.title:SetPoint("TOPLEFT", 10, -10)
    panel.title:SetTextColor(1, 0.82, 0, 1)

    panel.desc = addon_data.config.TextFactory(panel,
        L["Profiles let you save multiple layouts and quickly switch between them."], 12)
    panel.desc:SetPoint("TOPLEFT", 10, -40)
    panel.desc:SetTextColor(1, 1, 1, 1)

    -- Dropdown
    panel.profile_dropdown = CreateFrame("Frame", addon_name .. "ProfileDropDown", panel, "UIDropDownMenuTemplate")
    panel.profile_dropdown:SetPoint("TOPLEFT", 10, -70)

    local function GetCurrentProfile()
        return addon_data.db and addon_data.db:GetCurrentProfile() or "Default"
    end

    local function RefreshDropdownText()
        UIDropDownMenu_SetText(panel.profile_dropdown, GetCurrentProfile())
    end

    local function RefreshAllAfterProfileChange()
        -- Rebind aliases from DB (your helper from InitDB)
        if addon_data.core.RefreshFromDB then
            addon_data.core.RefreshFromDB()
        end

        -- Update config panels if you have a global updater
        if addon_data.core.UpdateAllVisualsOnSettingsChange then
            addon_data.core.UpdateAllVisualsOnSettingsChange()
        end
    end

    local function InitializeDropDown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(btn)
            addon_data.db:SetProfile(btn.value)
            RefreshDropdownText()
            RefreshAllAfterProfileChange()
        end

        -- List existing profiles
        local profiles = addon_data.db:GetProfiles()
        table.sort(profiles)
        for _, name in ipairs(profiles) do
            info.text = name
            info.value = name
            info.checked = (name == GetCurrentProfile())
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(panel.profile_dropdown, InitializeDropDown)
    UIDropDownMenu_SetWidth(panel.profile_dropdown, 140)
    RefreshDropdownText()

    -- New profile name box
    panel.new_profile_editbox = addon_data.config.EditBoxFactory(
        "WSTNewProfileEditBox",
        panel,
        L["New profile name"],
        160,
        25,
        function()
            panel.new_profile_editbox:SetMaxLetters(20)
        end
    )
    panel.new_profile_editbox:SetPoint("TOPLEFT", 205, -75)

    -- Create button
    panel.create_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.create_btn:SetSize(90, 22)
    panel.create_btn:SetPoint("LEFT", panel.new_profile_editbox, "RIGHT", 10, 0)
    panel.create_btn:SetText(L["Create"])
    panel.create_btn:SetScript("OnClick", function()
        local name = panel.new_profile_editbox:GetText()
        if not name or name == "" then return end
        addon_data.db:SetProfile(name)
        panel.new_profile_editbox:SetText("")
        UIDropDownMenu_Initialize(panel.profile_dropdown, InitializeDropDown)
        RefreshDropdownText()
        RefreshAllAfterProfileChange()
    end)

    -- Copy From (dropdown)
    panel.copy_from_dropdown = CreateFrame("Frame", addon_name .. "CopyFromDropDown", panel, "UIDropDownMenuTemplate")
    panel.copy_from_dropdown:SetPoint("TOPLEFT", 10, -110)
    UIDropDownMenu_SetWidth(panel.copy_from_dropdown, 140)
    UIDropDownMenu_SetText(panel.copy_from_dropdown, L["Copy from..."])

    local function InitializeCopyFrom(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(btn)
            -- copy chosen profile into current
            addon_data.db:CopyProfile(btn.value)
            UIDropDownMenu_SetText(panel.copy_from_dropdown, L["Copy from..."])
            RefreshAllAfterProfileChange()
        end

        local current = GetCurrentProfile()
        local profiles = addon_data.db:GetProfiles()
        table.sort(profiles)
        for _, name in ipairs(profiles) do
            if name ~= current then
                info.text = name
                info.value = name
                info.checked = false
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
    UIDropDownMenu_Initialize(panel.copy_from_dropdown, InitializeCopyFrom)

    StaticPopupDialogs["WST_CONFIRM_DELETE_PROFILE"] = {
        text = L["Delete active profile? This cannot be undone."],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self, profileName)
            if not addon_data or not addon_data.db or not profileName then return end
            if profileName == "Default" then return end

            -- Must switch away before deleting (AceDB requirement)
            addon_data.db:SetProfile("Default")
            addon_data.db:DeleteProfile(profileName)

            -- Refresh bindings/UI
            if addon_data.core and addon_data.core.RefreshFromDB then
                addon_data.core.RefreshFromDB()
            end
            UIDropDownMenu_SetText(panel.profile_dropdown, addon_data.db:GetCurrentProfile())
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["WST_CONFIRM_RESET_PROFILE"] = {
        text = L["Reset profile to defaults?"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self, profileName)
            if not addon_data or not addon_data.db then return end
            addon_data.db:ResetProfile()
            if addon_data.core and addon_data.core.RefreshFromDB then
                addon_data.core.RefreshFromDB()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- Reset profile button
    panel.reset_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.reset_btn:SetSize(150, 22)
    panel.reset_btn:SetPoint("LEFT", panel.copy_from_dropdown, "RIGHT", 10, 0)
    panel.reset_btn:SetText(L["Reset Active Profile"])
    panel.reset_btn:SetScript("OnClick", function()
        StaticPopup_Show("WST_CONFIRM_RESET_PROFILE", addon_data.db:GetCurrentProfile(), nil, addon_data.db:GetCurrentProfile())

        RefreshAllAfterProfileChange()
    end)

    panel.delete_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.delete_btn:SetSize(150, 22)
    panel.delete_btn:SetPoint("TOPLEFT", 30, -150)
    panel.delete_btn:SetText(L["Delete Active Profile"])
    panel.delete_btn:SetScript("OnClick", function()
        local current = addon_data.db:GetCurrentProfile()
        if current == "Default" then return end
        StaticPopup_Show("WST_CONFIRM_DELETE_PROFILE", current, nil, current)

                -- Refresh UI / bindings
        if addon_data.core.RefreshFromDB then
            addon_data.core.RefreshFromDB()
        end

        RefreshAllAfterProfileChange()
        -- Rebuild dropdowns / labels if you do that
        UIDropDownMenu_SetText(panel.profile_dropdown, addon_data.db:GetCurrentProfile())
    end)

    panel:SetHeight(220)
end

