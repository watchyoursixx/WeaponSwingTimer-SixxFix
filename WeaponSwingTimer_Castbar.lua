local addon_name, addon_data = ...
local L = addon_data.localization_table
--- define addon structure from the above local variable
addon_data.castbar = {}
--- declare array for ranks of all abilities, cast times, cooldown, based on spell ID
addon_data.castbar.shot_spell_ids = {
    [75] = {spell_name = L["Auto Shot"], rank = nil, cast_time = nil, cooldown = nil},
	[5384] = {spell_name = L["Feign Death"], rank = nil, cast_time = nil, cooldown = nil},
	[19506] = {spell_name = L["Trueshot Aura"], rank = 1, cast_time = nil, cooldown = nil},
	[20905] = {spell_name = L["Trueshot Aura"], rank = 2, cast_time = nil, cooldown = nil},
	[20906] = {spell_name = L["Trueshot Aura"], rank = 3, cast_time = nil, cooldown = nil},
    [2643] = {spell_name = L["Multi-Shot"], rank = 1, cast_time = 0.45, cooldown = 10},
    [14288] = {spell_name = L["Multi-Shot"], rank = 2, cast_time = 0.45, cooldown = 10},
    [14289] = {spell_name = L["Multi-Shot"], rank = 3, cast_time = 0.45, cooldown = 10},
    [14290] = {spell_name = L["Multi-Shot"], rank = 4, cast_time = 0.45, cooldown = 10},
    [25294] = {spell_name = L["Multi-Shot"], rank = 5, cast_time = 0.45, cooldown = 10},
    [19434] = {spell_name = L["Aimed Shot"], rank = 1, cast_time = 2.61, cooldown = 6},
    [20900] = {spell_name = L["Aimed Shot"], rank = 2, cast_time = 2.61, cooldown = 6},
    [20901] = {spell_name = L["Aimed Shot"], rank = 3, cast_time = 2.61, cooldown = 6},
    [20902] = {spell_name = L["Aimed Shot"], rank = 4, cast_time = 2.61, cooldown = 6},
    [20903] = {spell_name = L["Aimed Shot"], rank = 5, cast_time = 2.61, cooldown = 6},
    [20904] = {spell_name = L["Aimed Shot"], rank = 6, cast_time = 2.61, cooldown = 6},
    [5019] = {spell_name = L["Shoot"], rank = nil, cast_time = nil, cooldown = nil}
}
--- is spell multi-shot defined by spell_id
addon_data.castbar.is_spell_multi_shot = function(spell_id)
    if (spell_id == 2643) or (spell_id == 14288) or (spell_id == 14289) or 
       (spell_id == 14290) or (spell_id == 25294) then
            return true
    else
            return false
    end
end
--- is spell aimed shot defined by spell_id
addon_data.castbar.is_spell_aimed_shot = function(spell_id)
    if (spell_id == 19434) or (spell_id == 20900) or (spell_id == 20901) or 
       (spell_id == 20902) or (spell_id == 20903) or (spell_id == 20904) then
            return true
    else
            return false
    end
end
--- is spell auto shot defined by spell_id
addon_data.castbar.is_spell_auto_shot = function(spell_id)
    return (spell_id == 75)
end
--- is spell shoot defined by spell_id
addon_data.castbar.is_spell_shoot = function(spell_id)
    return (spell_id == 5019)
end
--- default settings to be loaded on initial load and reset to default
addon_data.castbar.default_settings = {
	width = 300,
	height = 12,
	fontsize = 12,
    point = "CENTER",
	rel_point = "CENTER",
	x_offset = 0,
	y_offset = -260,
	in_combat_alpha = 1.0,
	ooc_alpha = 0.0,
	backplane_alpha = 0.5,
    show_text = true,
    show_multishot_cast_bar = true,
    show_latency_bars = false,
    show_border = false
}
--- Initializing variables for calculations and function calls
addon_data.castbar.shooting = false
-- added check below for range speed to default 3 on initialize 
addon_data.castbar.range_speed = 3
addon_data.castbar.auto_cast_time = 0.50
addon_data.castbar.shot_timer = 0.50
addon_data.castbar.last_shot_time = GetTime()
addon_data.castbar.auto_shot_ready = true
addon_data.castbar.FeignStatus = false
addon_data.castbar.FeignFullReset = false
addon_data.castbar.range_auto_speed_modified = 1

addon_data.castbar.casting = false
addon_data.castbar.casting_shot = false
addon_data.castbar.casting_spell_id = 0
addon_data.castbar.cast_timer = 0.1
addon_data.castbar.cast_time = 0.1
addon_data.castbar.last_failed_time = GetTime()
addon_data.castbar.range_cast_speed_modifer = 1
addon_data.castbar.cast_start_time = GetTime()

addon_data.castbar.range_weapon_id = 0
addon_data.castbar.has_moved = false
addon_data.castbar.berserk_haste = 1
addon_data.castbar.class = 0
addon_data.castbar.guid = 0
addon_data.castbar.cast_total_time = 0
addon_data.castbar.hitcount = 0
addon_data.castbar.initial_pushback_time = 0
addon_data.castbar.initial_cast_time = 0
addon_data.castbar.total_pushback = 0
addon_data.castbar.cast_start_time_test = GetTime()


--- The below 3 functions check upon beginning to cast spell, use action, etc to call StartCastingSpell
addon_data.castbar.OnUseAction = function(action_id)
    addon_data.castbar.scan_tip:SetAction(action_id)
    name, _, _, cast_time, _, _, real_spell_id = GetSpellInfo(WSTScanTipTextLeft1:GetText())
	
end

addon_data.castbar.OnCastSpellByName = function(name, on_self)
    name, _, _, cast_time, _, _, real_spell_id = GetSpellInfo(name)
end

addon_data.castbar.OnCastSpell = function(spell_id, spell_book_type)
    name, _, _, cast_time, _, _, real_spell_id = GetSpellInfo(spell_id, spell_book_type)
end

addon_data.castbar.CastPushback = function()
	if addon_data.castbar.casting_shot then
	        -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        addon_data.castbar.pushbackValue = addon_data.castbar.pushbackValue or 1

		if ((GetTime() - addon_data.castbar.cast_start_time) < 1) and (addon_data.castbar.hitcount < 1) then
			addon_data.castbar.initial_pushback_time = GetTime() - addon_data.castbar.cast_start_time
		end

		if addon_data.castbar.initial_pushback_time > 0 then
			addon_data.castbar.cast_time = addon_data.castbar.cast_time + addon_data.castbar.initial_pushback_time
			addon_data.castbar.initial_pushback_time = 0
			addon_data.castbar.pushbackValue = 1
		else
			addon_data.castbar.cast_time = addon_data.castbar.cast_time + addon_data.castbar.pushbackValue
		end

		addon_data.castbar.hitcount = addon_data.castbar.hitcount + 1

        addon_data.castbar.pushbackValue = max(addon_data.castbar.pushbackValue - 0.2, 0.2)
		
		return
	end
end

-- Selection of starting a timer for casting multi and handling of stopping auto timer from starting
addon_data.castbar.StartCastingSpell = function(spell_id)
    local settings = character_castbar_settings

    if (GetTime() - addon_data.castbar.last_failed_time) > 0 then
        if not addon_data.castbar.casting and UnitCanAttack('player', 'target') then
            spell_name, _, _, cast_time, _, _, _ = GetSpellInfo(spell_id)
            if cast_time == nil then
			
                return 
            end
            if not addon_data.castbar.is_spell_auto_shot(spell_id) and 
               not addon_data.castbar.is_spell_shoot(spell_id) and cast_time > 0 then
                    addon_data.castbar.casting = true
            end

			if (not addon_data.castbar.casting_shot) and (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar) then
				addon_data.castbar.cast_start_time = GetTime()
				addon_data.castbar.casting_shot = true
				addon_data.castbar.casting_spell_id = spell_id
				addon_data.castbar.pushbackValue = 1
				addon_data.castbar.initial_pushback_time = 0
				addon_data.castbar.initial_cast_time = cast_time
                    
				addon_data.castbar.cast_timer = 0
				addon_data.castbar.frame.spell_bar:SetVertexColor(0.7, 0.4, 0, 1)

				if settings.show_latency_bars then
					local _, _, _, latency = GetNetStats()
					addon_data.castbar.cast_time = addon_data.castbar.cast_time + (latency / 1000)
				end
				if settings.show_text then
					addon_data.castbar.frame.spell_text_center:SetText(spell_name)
				end
			end	
		end
	end
end

addon_data.castbar.LoadSettings = function()
    -- If the carried over settings dont exist then make them
    if not character_castbar_settings then
        character_castbar_settings = {}
        _, class, _ = UnitClass("player")
        character_castbar_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.castbar.default_settings) do
        if character_castbar_settings[setting] == nil then
            character_castbar_settings[setting] = value
        end
    end
    hooksecurefunc('UseAction', addon_data.castbar.OnUseAction)
    hooksecurefunc('CastSpellByName', addon_data.castbar.OnCastSpellByName)
    hooksecurefunc('CastSpell', addon_data.castbar.OnCastSpell)
    addon_data.castbar.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
    addon_data.castbar.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

addon_data.castbar.RestoreDefaults = function()
    for setting, value in pairs(addon_data.castbar.default_settings) do
        character_castbar_settings[setting] = value
    end
    _, class, _ = UnitClass("player")
    character_castbar_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateConfigPanelValues()
end

--- verify weapon speed, class, guid
addon_data.castbar.UpdateInfo = function()
    addon_data.castbar.range_weapon_id = GetInventoryItemID("player", 18)
    addon_data.castbar.class = UnitClass("player")[2]
    addon_data.castbar.guid = UnitGUID("player")
end


--- Buffs and debuffs change casting speeds, which is multiplied by the cast time
--- -----------------------------------------------------------------------------
--- Anything that changes cast times should go here. Need to add other forms of debuffs
--- berserk haste is a simple calculation to derive the percent of berserking haste provided to the player from their health percent
addon_data.castbar.UpdateRangeCastSpeedModifier = function()
    local speed = 1.0
    local buffs = {3045, 26635, 6150, 28866, 12889} -- aura ids for each haste effect
	for i=1, 40 do
        local _, _, _, _, _, _, _, _, _, buffId = UnitBuff("player",i)
		-- name, _ = UnitAura("player", i)
        if buffId == buffs[3] then -- Quick Shots 
		-- if name == "Quick Shots" then
            speed = speed/1.3
        end
        if buffId == buffs[1] then -- Rapid Fire 
		-- if name == "Rapid Fire" then
            speed = speed/1.4
        end
        if buffId == buffs[2] then -- Troll Racial 
		-- if name == "Berserking" then
            addon_data.castbar.UpdateBerserkHaste()
            speed = speed/ (addon_data.castbar.berserk_haste)
        end
        if buffId == buffs[4] then -- Kiss of the Spider 
		-- if name == "Kiss of the Spider" then
            speed = speed/1.2
        end
		if buffId == buffs[5] then -- Curse of Tongues
        -- if name == "Curse of Tongues" then
            speed = speed/0.5
        end
    end
    addon_data.castbar.range_cast_speed_modifer = speed
end

addon_data.castbar.UpdateBerserkHaste = function()
	
    if((UnitHealth("player")/UnitHealthMax("player") >= 0.40)) then
        addon_data.castbar.berserk_haste = (1.30 - (UnitHealth("player")/UnitHealthMax("player")-0.40)/2)
    else
        addon_data.castbar.berserk_haste =  1.3
    end
end

addon_data.castbar.UpdateCastTimer = function(elapsed)
	
	local base_cast_time = addon_data.castbar.shot_spell_ids[addon_data.castbar.casting_spell_id].cast_time
	
	if (addon_data.castbar.cast_timer < 0.25) then
		addon_data.castbar.cast_time = base_cast_time * addon_data.castbar.range_cast_speed_modifer
	end
	
    addon_data.castbar.cast_timer = GetTime() - addon_data.castbar.cast_start_time
    if addon_data.castbar.cast_timer > addon_data.castbar.cast_time + 0.5 then
        addon_data.castbar.OnUnitSpellCastFailed('player', 1)
    end
	
	addon_data.castbar.total_pushback = addon_data.castbar.cast_time - addon_data.castbar.initial_cast_time
end

addon_data.castbar.OnUpdate = function(elapsed)
    if character_castbar_settings.enabled then

        -- Update the cast bar timers
        if addon_data.castbar.casting_shot then
            addon_data.castbar.UpdateCastTimer(elapsed)
        end
        -- Update the visuals
        addon_data.castbar.UpdateVisualsOnUpdate()
    end
end

-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
addon_data.castbar.OnCombatLogUnfiltered = function(combat_info)
    local _, event, _, casterID, _, _, _, targetID, targetName, _, _, spellID, name, _ = unpack(combat_info)
	local _, rank, icon, castTime = GetSpellInfo(spellID)
	local icon, castTime = select(3, GetSpellInfo(spellID))
	if casterID == UnitGUID("player") then
	
		if event == "SPELL_CAST_START" then
		  
				addon_data.hunter.FeignStatus = false
				addon_data.castbar.StartCastingSpell(real_spell_id)
		return end
	
		if event == "SPELL_CAST_SUCCESS" then

		return end
	end		
		
	
	if event == "SWING_MISSED" or event == "RANGE_MISSED" or event == "SPELL_MISSED" then	return end
	if event == "SWING_DAMAGE" or event == "ENVIRONMENTAL_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" then	
	
		if targetID == UnitGUID("player") then
			addon_data.castbar.CastPushback()
		end
	return end
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
addon_data.castbar.OnUnitSpellCastSucceeded = function(unit, spell_id)

	local settings = character_castbar_settings

  if unit == 'player' then
	
	      addon_data.castbar.casting = false
        -- If the spell is Auto Shot then reset the shot timer
        if addon_data.castbar.shot_spell_ids[spell_id] then
            spell_name = addon_data.castbar.shot_spell_ids[spell_id].spell_name

			if addon_data.castbar.is_spell_aimed_shot(spell_id) then

				addon_data.hunter.FeignDeath()
			end
			addon_data.castbar.casting_spell_id = 0
            addon_data.castbar.casting_shot = false
			-- only show green bar overlay if setting is enabled
			if (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar) then
				addon_data.castbar.frame.spell_bar:SetVertexColor(0, 0.5, 0, 1)
				addon_data.castbar.frame.spell_bar:SetWidth(character_castbar_settings.width)
				addon_data.castbar.frame.spell_bar_text:SetText("0.0")
			end
            
        end

    end
end

addon_data.castbar.OnUnitSpellCastFailed = function(unit, spell_id)
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame
	-- only care about if multi fails to cast, so ignore others
    if unit == 'player' and (addon_data.castbar.is_spell_multi_shot(spell_id)) then

        addon_data.castbar.last_failed_time = GetTime()
        addon_data.castbar.casting = false
		addon_data.castbar.pushbackValue = 1
		addon_data.castbar.initial_pushback_time = 0
		addon_data.castbar.hitcount = 0
		
        if addon_data.castbar.casting_spell_id > 0 and (addon_data.castbar.is_spell_multi_shot(spell_id)) then
		
            addon_data.castbar.casting_shot = false
            addon_data.castbar.casting_spell_id = 0
			if (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar) then
				addon_data.castbar.frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
				if character_castbar_settings.show_text then
					frame.spell_text_center:SetText(L["Failed"])
				end
				frame.spell_bar:SetWidth(settings.width)
			end
        end
    end
end

addon_data.castbar.OnUnitSpellCastInterrupted = function(unit, spell_id)
    local settings = character_castbar_settings
	local frame = addon_data.castbar.frame
	if unit == 'player' and (addon_data.castbar.is_spell_multi_shot(spell_id)) then
	
        addon_data.castbar.casting = false
		addon_data.castbar.pushbackValue = 1
		addon_data.castbar.initial_pushback_time = 0
		addon_data.castbar.hitcount = 0
		
        if addon_data.castbar.casting_spell_id > 0 and (addon_data.castbar.is_spell_multi_shot(spell_id)) then
            addon_data.castbar.casting_shot = false
            addon_data.castbar.casting_spell_id = 0
			
			if (addon_data.castbar.is_spell_multi_shot(spell_id) and settings.show_multishot_cast_bar) then
				frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
				if settings.show_text then
					frame.spell_text_center:SetText(L["Interrupted"])
				end
				frame.spell_bar:SetWidth(settings.width)
			end
        end
    end
end

--- Updating and initializing visuals
--- ---------------------------------
addon_data.castbar.UpdateVisualsOnUpdate = function()
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame

    if addon_data.core.in_combat or addon_data.castbar.casting_shot then
		if addon_data.castbar.casting_shot then
			local time_left = math.max(addon_data.utils.SimpleRound(addon_data.castbar.cast_time - addon_data.castbar.cast_timer, 0.1), 0)
			frame.spell_bar_text:SetText(string.format("%.1f", time_left))
			frame:SetAlpha(1)
			new_width = settings.width * (addon_data.castbar.cast_timer / addon_data.castbar.cast_time)
			new_width = math.min(new_width, settings.width)
			frame.spell_bar:SetWidth(new_width)
			frame.spell_spark:SetPoint('TOPLEFT', new_width - 8, 0)
			if new_width == settings.width or not settings.classic_bars then
				frame.spell_spark:Hide()
			else
				frame.spell_spark:Show()
			end
		else
			new_alpha = frame:GetAlpha() - 0.005
			if new_alpha <= 0 then
				new_alpha = 0
				frame:SetSize(settings.width, settings.height)
				frame.spell_text_center:SetText("")
				frame.spell_bar_text:SetText("")
			end
			frame:SetAlpha(new_alpha)
			frame.spell_spark:Hide()
		end
		if settings.show_latency_bars then
				if addon_data.castbar.casting_shot then
				frame.cast_latency:Show()
				_, _, _, latency = GetNetStats()
				lag_width = settings.width * ((latency / 1000) / addon_data.castbar.cast_time)
				frame.cast_latency:SetWidth(lag_width)
			else
				frame.cast_latency:Hide()
		end
	end
	else
        frame:SetAlpha(settings.ooc_alpha)
    end
end

addon_data.castbar.UpdateVisualsOnSettingsChange = function()
    local settings = character_castbar_settings
    local frame = addon_data.castbar.frame
	if settings.enabled then
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        if settings.show_border then
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border", 
                tile = true, tileSize = 16, edgeSize = 12, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        else
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = nil, 
                tile = true, tileSize = 16, edgeSize = 16, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        end
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)

        frame.spell_bar_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.spell_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
		frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
		
        frame.spell_bar:SetPoint("TOPLEFT", 0, 0)
        frame.spell_bar:SetHeight(settings.height)

		frame.spell_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        frame.spell_spark:SetSize(16, settings.height)
        frame.spell_text_center:SetPoint("TOP", 2, -(settings.height / 2) + (settings.fontsize / 2))
		frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
		
		frame.cast_latency:SetHeight(settings.height)
        frame.cast_latency:SetPoint("TOPLEFT", 0, 0)
        frame.cast_latency:SetColorTexture(1, 0, 0, 0.75)
        if settings.show_latency_bars then
            frame.cast_latency:Show()
        else
            frame.cast_latency:Hide()
        end

        if settings.show_text then
            frame.spell_text_center:Show()
            frame.spell_bar_text:Show()
        else
            frame.spell_text_center:Hide()
            frame.spell_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

addon_data.castbar.OnFrameDragStart = function()
    if not character_castbar_settings.is_locked then
        addon_data.castbar.frame:StartMoving()
    end
end

addon_data.castbar.OnFrameDragStop = function()
    local frame = addon_data.castbar.frame
    local settings = character_castbar_settings
    frame:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateConfigPanelValues()
end

addon_data.castbar.InitializeVisuals = function()
    local settings = character_castbar_settings
    -- Create the frame
    addon_data.castbar.frame = CreateFrame("Frame", addon_name .. "HunterAutoshotFrame", UIParent)
    local frame = addon_data.castbar.frame
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.castbar.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.castbar.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint('TOPLEFT', -9, 9)
    frame.backplane:SetPoint('BOTTOMRIGHT', 9, -9)
    frame.backplane:SetFrameStrata('BACKGROUND')

    -- Create the range spell shot bar
    frame.spell_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the spell bar text
    frame.spell_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_bar_text:SetJustifyV("CENTER")
    frame.spell_bar_text:SetJustifyH("CENTER")
    -- Create the spell spark
    frame.spell_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.spell_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the range spell shot bar center text
    frame.spell_text_center = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_text_center:SetTextColor(1, 1, 1, 1)
    frame.spell_text_center:SetJustifyV("CENTER")
    frame.spell_text_center:SetJustifyH("LEFT")
    -- Create the latency bar
    frame.cast_latency = frame:CreateTexture(nil,"OVERLAY")
    -- Show it off
    addon_data.castbar.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateVisualsOnUpdate()
    frame:Show()
end



--- Everything below is designated as part of the UI settings menu. Checkboxes, adjustments, sliders
--- ------------------------------------------------------------------------------------------------
--- Adjusts the values of everything based on the settings selected with UpdateConfigPanelValues
--- 10 boxes that can be checked, all exact same just with different names
--- Bar height, width, and offset values set with numerical value
--- Color picker selection for 3 visual displays of the bars
--- Alpha adjustments for 3 visual displays of the bars
addon_data.castbar.UpdateConfigPanelValues = function()
    local panel = addon_data.castbar.config_frame
    local settings = character_castbar_settings
    panel.show_multishot_cast_bar_checkbox:SetChecked(settings.show_multishot_cast_bar)
    panel.show_latency_bar_checkbox:SetChecked(settings.show_latency_bars)
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
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

addon_data.castbar.ShowMultiShotCastBarCheckBoxOnClick = function(self)
    character_castbar_settings.show_multishot_cast_bar = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.ShowLatencyBarsCheckBoxOnClick = function(self)
    character_castbar_settings.show_latency_bars = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.ShowTextCheckBoxOnClick = function(self)
    character_castbar_settings.show_text = self:GetChecked()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.WidthEditBoxOnEnter = function(self)
    character_castbar_settings.width = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.HeightEditBoxOnEnter = function(self)
    character_castbar_settings.height = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.FontSizeEditBoxOnEnter = function(self)
    character_castbar_settings.fontsize = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.XOffsetEditBoxOnEnter = function(self)
    character_castbar_settings.x_offset = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.YOffsetEditBoxOnEnter = function(self)
    character_castbar_settings.y_offset = tonumber(self:GetText())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.CombatAlphaOnValChange = function(self)
    character_castbar_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.OOCAlphaOnValChange = function(self)
    character_castbar_settings.ooc_alpha = tonumber(self:GetValue())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

addon_data.castbar.BackplaneAlphaOnValChange = function(self)
    character_castbar_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end
--- Initializes the main setting panel including layout, alignment, and design
addon_data.castbar.CreateConfigPanel = function(parent_panel)
    addon_data.castbar.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = addon_data.castbar.config_frame
    local settings = character_castbar_settings
    
    -- Show Border Checkbox
    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowBorderCheckBox",
        panel,
        L["Show border"],
        L["Enables the shot bar's border."],
        addon_data.castbar.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -90)
    
    -- Show Text Checkbox
    panel.show_text_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowTextCheckBox",
        panel,
        L["Show Text"],
        L["Enables the shot bar text."],
        addon_data.castbar.ShowTextCheckBoxOnClick)
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -150)
    
    -- Width EditBox
    panel.width_editbox = addon_data.config.EditBoxFactory(
        "HunterWidthEditBox",
        panel,
        L["Bar Width"],
        75,
        25,
        addon_data.castbar.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -90, "BOTTOMRIGHT", 275, -115)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "HunterHeightEditBox",
        panel,
        L["Bar Height"],
        75,
        25,
        addon_data.castbar.HeightEditBoxOnEnter)
	panel.height_editbox:SetPoint("TOPLEFT", 320, -90, "BOTTOMRIGHT", 225, -115)
	-- Font Size EditBox
	panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        addon_data.castbar.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterXOffsetEditBox",
        panel,
        L["X Offset"],
        75,
        25,
        addon_data.castbar.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -140, "BOTTOMRIGHT", 275, -165)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterYOffsetEditBox",
        panel,
        L["Y Offset"],
        75,
        25,
        addon_data.castbar.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -140, "BOTTOMRIGHT", 225, -165)
         
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "HunterInCombatAlphaSlider",
        panel,
        L["In Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.castbar.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -90)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "HunterOOCAlphaSlider",
        panel,
        L["Out of Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.castbar.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "HunterBackplaneAlphaSlider",
        panel,
        L["Backplane Alpha"],
        0,
        1,
        0.05,
        addon_data.castbar.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -190)
    
    -- Hunter Specific Settings Text
    panel.hunter_text = addon_data.config.TextFactory(panel, L["Hunter Specific Settings"], 16)
    panel.hunter_text:SetPoint("TOPLEFT", 10 , -250)
    panel.hunter_text:SetTextColor(1, 0.9, 0, 1)
    
    -- Show Multi Shot Cast Bar Checkbox
    panel.show_multishot_cast_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowMultiShotCastBarCheckBox",
        panel,
        L["Multi-Shot cast bar"],
        L["Allows the cast bar to show Multi-Shot casts."],
        addon_data.castbar.ShowMultiShotCastBarCheckBoxOnClick)
    panel.show_multishot_cast_bar_checkbox:SetPoint("TOPLEFT", 10, -270)
    
    -- Show Latency Bar Checkbox
    panel.show_latency_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowLatencyBarCheckBox",
        panel,
        L["Latency bar"],
        L["Shows a bar that represents latency on cast bar."],
        addon_data.castbar.ShowLatencyBarsCheckBoxOnClick)
    panel.show_latency_bar_checkbox:SetPoint("TOPLEFT", 10, -290)
    
    -- Return the final panel
    addon_data.castbar.UpdateConfigPanelValues()
    return panel
end
