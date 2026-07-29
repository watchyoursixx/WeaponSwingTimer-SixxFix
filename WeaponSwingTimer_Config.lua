local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.config = {}

addon_data.config.OnDefault = function()
    addon_data.core.RestoreAllDefaults()
    addon_data.config.UpdateConfigValues()
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
    addon_data.config.category = category
    Settings.RegisterAddOnCategory(category)
    
    -- Add the melee panel
    panel.config_melee_panel = CreateFrame("Frame", nil, panel)
    panel.config_melee_panel:SetSize(1, 1)
    panel.config_melee_panel.player_panel = addon_data.player.CreateConfigPanel(panel.config_melee_panel)
    panel.config_melee_panel.player_panel:SetPoint('TOPLEFT', 0, 0)
    panel.config_melee_panel.player_panel:SetSize(1, 1)
    panel.config_melee_panel.target_panel = addon_data.target.CreateConfigPanel(panel.config_melee_panel)
    panel.config_melee_panel.target_panel:SetPoint('TOPLEFT', 0, -275)
    panel.config_melee_panel.target_panel:SetSize(1, 1)
    panel.config_melee_panel.name = L["Melee Settings"]
    panel.config_melee_panel.parent = panel.name
    panel.config_melee_panel.default = addon_data.config.OnDefault
    Settings.RegisterCanvasLayoutSubcategory(category, panel.config_melee_panel, panel.config_melee_panel.name)
    
    -- Add the hunter panel
    panel.config_hunter_panel = CreateFrame("Frame", nil, panel)
    panel.config_hunter_panel:SetSize(1, 1)
    panel.config_hunter_panel.hunter_panel = addon_data.hunter.CreateConfigPanel(panel.config_hunter_panel)
    local hunter_panel_height = 290
    panel.config_hunter_panel.hunter_panel:SetHeight(hunter_panel_height)
    panel.config_hunter_panel.hunter_panel:SetSize(1, 1)
    panel.config_hunter_panel.hunter_panel:SetPoint('TOPLEFT', 0, 0)
    
    panel.config_hunter_panel.castbar_panel = addon_data.castbar.CreateConfigPanel(panel.config_hunter_panel)	
    panel.config_hunter_panel.castbar_panel:SetHeight(250)
    panel.config_hunter_panel.castbar_panel:SetSize(1, 1)
    local castbar_panel_position = - 10 - hunter_panel_height
    panel.config_hunter_panel.castbar_panel:SetPoint("TOPLEFT",0, castbar_panel_position)

    local totalHeight = panel.config_hunter_panel.hunter_panel:GetHeight() + panel.config_hunter_panel.castbar_panel:GetHeight() + 30
    panel.config_hunter_panel:SetHeight(totalHeight)

    panel.config_hunter_panel.name = L["Ranged Settings"]
    panel.config_hunter_panel.parent = panel.name
    panel.config_hunter_panel.default = addon_data.config.OnDefault
    Settings.RegisterCanvasLayoutSubcategory(category, panel.config_hunter_panel, panel.config_hunter_panel.name)

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

addon_data.config.CheckBoxFactory = function(g_name, parent, checkbtn_text, tooltip_text, on_click_func)
    local checkbox = CreateFrame("CheckButton", addon_name .. g_name, parent, "ChatConfigCheckButtonTemplate")
    getglobal(checkbox:GetName() .. 'Text'):SetText(checkbtn_text)
    checkbox.tooltip = tooltip_text
    checkbox:SetScript("OnClick", function(self)
        on_click_func(self)
    end)
    checkbox:SetScale(1.1)
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
    local start_r = settings[name .. "_r"]
    local start_g = settings[name .. "_g"]
    local start_b = settings[name .. "_b"]
    local start_a = settings[name .. "_a"]

    local function Apply()
        local new_r, new_g, new_b = ColorPickerFrame:GetColorRGB()
        local new_a = 1 - OpacitySliderFrame:GetValue()

        settings[name .. "_r"] = new_r
        settings[name .. "_g"] = new_g
        settings[name .. "_b"] = new_b
        settings[name .. "_a"] = new_a

        foreground_texture:SetColorTexture(new_r, new_g, new_b, new_a)
        if on_change then on_change(new_r, new_g, new_b, new_a) end
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = start_r,
        g = start_g,
        b = start_b,
        hasOpacity = true,
        opacity = 1 - start_a,
        swatchFunc = Apply,
        opacityFunc = Apply,
        cancelFunc = function()
            settings[name .. "_r"] = start_r
            settings[name .. "_g"] = start_g
            settings[name .. "_b"] = start_b
            settings[name .. "_a"] = start_a

            foreground_texture:SetColorTexture(start_r, start_g, start_b, start_a)
            if on_change then on_change(start_r, start_g, start_b, start_a) end
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
    character_castbar_settings.is_locked = self:GetChecked()
    addon_data.player.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.target.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.hunter.frame:EnableMouse(not character_target_settings.is_locked)
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

