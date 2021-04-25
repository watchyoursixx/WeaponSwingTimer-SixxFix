local addon_name, addon_data = ...
local L = addon_data.localization_table

--- define addon structure from the above local variable
addon_data.hunter = {}
--- declare array for ranks of all abilities, cast times, cooldown, based on spell ID
addon_data.hunter.shot_spell_ids = {
    [75] = {spell_name = L["Auto Shot"], rank = nil, cast_time = 0.5, cooldown = nil},
	[5384] = {spell_name = L["Feign Death"], rank = nil, cast_time = nil, cooldown = nil},
	[19506] = {spell_name = L["Trueshot Aura"], rank = 1, cast_time = nil, cooldown = nil},
	[20905] = {spell_name = L["Trueshot Aura"], rank = 2, cast_time = nil, cooldown = nil},
	[20906] = {spell_name = L["Trueshot Aura"], rank = 3, cast_time = nil, cooldown = nil},
    [2643] = {spell_name = L["Multi-Shot"], rank = 1, cast_time = 0.5, cooldown = 10},
    [14288] = {spell_name = L["Multi-Shot"], rank = 2, cast_time = 0.5, cooldown = 10},
    [14289] = {spell_name = L["Multi-Shot"], rank = 3, cast_time = 0.5, cooldown = 10},
    [14290] = {spell_name = L["Multi-Shot"], rank = 4, cast_time = 0.5, cooldown = 10},
    [25294] = {spell_name = L["Multi-Shot"], rank = 5, cast_time = 0.5, cooldown = 10},
    [19434] = {spell_name = L["Aimed Shot"], rank = 1, cast_time = 3, cooldown = 6},
    [20900] = {spell_name = L["Aimed Shot"], rank = 2, cast_time = 3, cooldown = 6},
    [20901] = {spell_name = L["Aimed Shot"], rank = 3, cast_time = 3, cooldown = 6},
    [20902] = {spell_name = L["Aimed Shot"], rank = 4, cast_time = 3, cooldown = 6},
    [20903] = {spell_name = L["Aimed Shot"], rank = 5, cast_time = 3, cooldown = 6},
    [20904] = {spell_name = L["Aimed Shot"], rank = 6, cast_time = 3, cooldown = 6},
    [5019] = {spell_name = L["Shoot"], rank = nil, cast_time = nil, cooldown = nil}
}
--- is spell multi-shot defined by spell_id
addon_data.hunter.is_spell_multi_shot = function(spell_id)
    if (spell_id == 2643) or (spell_id == 14288) or (spell_id == 14289) or 
       (spell_id == 14290) or (spell_id == 25294) then
            return true
    else
            return false
    end
end
--- is spell aimed shot defined by spell_id
addon_data.hunter.is_spell_aimed_shot = function(spell_id)
    if (spell_id == 19434) or (spell_id == 20900) or (spell_id == 20901) or 
       (spell_id == 20902) or (spell_id == 20903) or (spell_id == 20904) then
            return true
    else
            return false
    end
end
--- is spell auto shot defined by spell_id
addon_data.hunter.is_spell_auto_shot = function(spell_id)
    return (spell_id == 75)
end
--- is spell shoot defined by spell_id
addon_data.hunter.is_spell_shoot = function(spell_id)
    return (spell_id == 5019)
end
--- default settings to be loaded on initial load and reset to default
addon_data.hunter.default_settings = {
	enabled = true,
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
	is_locked = false,
    show_text = true,
    show_multishot_clip_bar = true,
	show_autoshot_delay_timer = true,
    show_border = false,
    classic_bars = true,
    one_bar = false,
    cooldown_r = 0.95, cooldown_g = 0.95, cooldown_b = 0.95, cooldown_a = 1.0,
    auto_cast_r = 0.8, auto_cast_g = 0.0, auto_cast_b = 0.0, auto_cast_a = 1.0,
    clip_r = 1.0, clip_g = 0.0, clip_b = 0.0, clip_a = 0.7
}
--- Initializing variables for calculations and function calls
addon_data.hunter.shooting = false
-- added check below for range speed to default 3 on initialize 
addon_data.hunter.range_speed = 3
addon_data.hunter.auto_cast_time = 0.52
addon_data.hunter.shot_timer = 0.52
addon_data.hunter.last_shot_time = GetTime()
addon_data.hunter.auto_shot_ready = true
addon_data.hunter.FeignStatus = false
addon_data.hunter.FeignFullReset = false
addon_data.hunter.range_auto_speed_modified = 1
addon_data.hunter.base_speed = 1

addon_data.hunter.casting = false
addon_data.hunter.casting_auto = false
addon_data.hunter.range_cast_speed_modifer = 1

addon_data.hunter.range_weapon_id = 0
addon_data.hunter.has_moved = false

-- handling of stopping auto timer from starting
addon_data.hunter.StartCastingSpell = function(spell_id)
    local settings = character_hunter_settings

    if not addon_data.hunter.casting and UnitCanAttack('player', 'target') then
        spell_name, _, _, cast_time, _, _, _ = GetSpellInfo(spell_id)
        if cast_time == nil then
			
            return 
        end
        if not addon_data.hunter.is_spell_auto_shot(spell_id) and 
			not addon_data.hunter.is_spell_shoot(spell_id) and cast_time > 0 then
               addon_data.hunter.casting = true
        end
	end
end

addon_data.hunter.LoadSettings = function()
    -- If the carried over settings dont exist then make them
    if not character_hunter_settings then
        character_hunter_settings = {}
        _, class, _ = UnitClass("player")
        character_hunter_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.hunter.default_settings) do
        if character_hunter_settings[setting] == nil then
            character_hunter_settings[setting] = value
        end
    end

    addon_data.hunter.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
    addon_data.hunter.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
end

addon_data.hunter.RestoreDefaults = function()
    for setting, value in pairs(addon_data.hunter.default_settings) do
        character_hunter_settings[setting] = value
    end
    _, class, _ = UnitClass("player")
    character_hunter_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateConfigPanelValues()
end

-- Replaced update info with this instead, checking weapon id every time inventory is changed for simplicity
addon_data.hunter.OnInventoryChange = function()
	local _, class, _ = UnitClass("player")
	if (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK") then
		addon_data.hunter.range_weapon_id = GetInventoryItemID("player", 18)
		local weapon_id = addon_data.hunter.range_weapon_id
	
		if weapon_id == nil then
			addon_data.hunter.base_speed = 1
		else
			addon_data.hunter.base_speed = addon_data.ranged_DB.item_ids[weapon_id].base_speed
		end
	end
end	

--- Reset Swing Timer unhasted separately due to feign and other spells
addon_data.hunter.FeignDeath = function()
    addon_data.hunter.last_shot_time = GetTime()
	if not addon_data.hunter.FeignFullReset then
		local weapon_id = GetInventoryItemID("player", 18)
		addon_data.hunter.range_speed = addon_data.ranged_DB.item_ids[weapon_id].base_speed + 0.15
		addon_data.hunter.FeignFullReset = true
	end
    addon_data.hunter.ResetShotTimer()
end

-- Modified to use base speed and current ranged speed, to get the haste modifiers. This is used in multi-shot cast bar to provide an accurate bar, as well as multi clip
addon_data.hunter.UpdateRangeCastSpeedModifier = function()
	local _, class, _ = UnitClass("player")
	
	if addon_data.hunter.base_speed == 1 and (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK") then 
		addon_data.hunter.range_weapon_id = GetInventoryItemID("player", 18)
		local weapon_id = addon_data.hunter.range_weapon_id
		-- added case for if no ranged equipped
		if weapon_id == nil then
			addon_data.hunter.base_speed = 1
		else
			addon_data.hunter.base_speed = addon_data.ranged_DB.item_ids[weapon_id].base_speed
		end
	else
		range_speed, _, _, _, _, _ = UnitRangedDamage("player")
		-- added case for if range speed returns nil or 0
		if range_speed == nil or range_speed == 0 then
			range_speed = 1
		else
			addon_data.hunter.range_cast_speed_modifer = range_speed / addon_data.hunter.base_speed
		end
	end
end


--- Update timer for auto shot based on various conditions
addon_data.hunter.ResetShotTimer = function()
    -- The timer is reset to either the auto cast time or the difference between the time since the last shot and the current time depending on which is larger
    local curr_time = GetTime()
    local range_speed = addon_data.hunter.range_speed
    if (curr_time + 0.05 - addon_data.hunter.last_shot_time) > (range_speed - addon_data.hunter.auto_cast_time) then
        addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
        addon_data.hunter.auto_shot_ready = true
		
    elseif curr_time ~= addon_data.hunter.last_shot_time and not addon_data.hunter.casting then
        addon_data.hunter.shot_timer = curr_time - addon_data.hunter.last_shot_time
        addon_data.hunter.auto_shot_ready = false
		
	elseif addon_data.hunter.casting then
		if (curr_time - addon_data.hunter.last_shot_time) > (3 * addon_data.hunter.range_cast_speed_modifer) then
			addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
		end
    else
        addon_data.hunter.shot_timer = range_speed
        addon_data.hunter.auto_shot_ready = false
    end
end

addon_data.hunter.UpdateAutoShotTimer = function(elapsed)
    local curr_time = GetTime()
	local shot_timer = addon_data.hunter.shot_timer
	local _, class, _ = UnitClass("player")
    if addon_data.hunter.shot_timer < 0 then
		addon_data.hunter.shot_timer = 0
	else
		addon_data.hunter.shot_timer = shot_timer - elapsed
	end
	if class == "WARLOCK" or class == "MAGE" or class == "PRIEST" then
		addon_data.hunter.auto_cast_time = 0.52
	else
		addon_data.hunter.UpdateRangeCastSpeedModifier()
		addon_data.hunter.auto_cast_time = 0.52 * addon_data.hunter.range_cast_speed_modifer
	end
	
    -- If the player moved then the timer resets
    if addon_data.hunter.has_moved or addon_data.hunter.casting then
        if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
            addon_data.hunter.ResetShotTimer()
        end
    end
    -- If the shot timer is less than the auto cast time then the auto shot is ready
    if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
        addon_data.hunter.auto_shot_ready = true
        -- If we are not shooting then the timer should be reset
        if not addon_data.hunter.shooting then
            addon_data.hunter.ResetShotTimer()
        end
    else
         addon_data.hunter.auto_shot_ready = false
    end
end

addon_data.hunter.OnUpdate = function(elapsed)
    if character_hunter_settings.enabled then
        -- Check to see if we have moved
        addon_data.hunter.has_moved = (GetUnitSpeed("player") > 0)
		
		-- Check for feign death movement that causes swing reset
		if addon_data.hunter.FeignStatus and addon_data.hunter.has_moved then
			addon_data.hunter.FeignDeath()
			addon_data.hunter.FeignStatus = false
		end
		
        -- Update the Auto Shot timer based on the updated settings
        addon_data.hunter.UpdateAutoShotTimer(elapsed)
        -- Update the visuals
        addon_data.hunter.UpdateVisualsOnUpdate()
    end
end
-- detecting jumps out of a feign death to trigger a reset 
hooksecurefunc("JumpOrAscendStart", function()
	if  addon_data.hunter.FeignStatus then  
			addon_data.hunter.FeignDeath()
			addon_data.hunter.FeignStatus = false
	end	  
end)


--- spell functions to determine the state of the spell being casted.
--- -----------------------------------------------------------------
--- Determines the state of shooting on or off
addon_data.hunter.OnStartAutorepeatSpell = function()
    addon_data.hunter.shooting = true
	
    if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
        addon_data.hunter.ResetShotTimer()
    end
end

addon_data.hunter.OnStopAutorepeatSpell = function()
    addon_data.hunter.shooting = false
end
-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
addon_data.hunter.OnCombatLogUnfiltered = function(combat_info)
    local _, event, _, casterID, _, _, _, targetID, targetName, _, _, spellID, name, _ = unpack(combat_info)
	local _, rank, icon, castTime = GetSpellInfo(spellID)
	local icon, castTime = select(3, GetSpellInfo(spellID))

	if casterID == UnitGUID("player") then
	
		if event == "SPELL_CAST_START" then
		
				addon_data.hunter.FeignStatus = false
				addon_data.hunter.StartCastingSpell(spellID)
				
				if addon_data.hunter.is_spell_auto_shot(spellID) then
					addon_data.hunter.casting_auto = true
				end
				
		return end
	
		if event == "SPELL_CAST_SUCCESS" then

		return end
	end		
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
addon_data.hunter.OnUnitSpellCastSucceeded = function(unit, spell_id)

	local settings = character_hunter_settings
	if unit == 'player' then
	
	    addon_data.hunter.casting = false
        -- If the spell is Auto Shot then reset the shot timer
        if addon_data.hunter.shot_spell_ids[spell_id] then
            spell_name = addon_data.hunter.shot_spell_ids[spell_id].spell_name
			if spell_name == L["Feign Death"] or spell_name == L["Trueshot Aura"] then
				if spell_name == L["Feign Death"] then
					addon_data.hunter.FeignStatus = true
				end
				addon_data.hunter.FeignDeath()
				return
			end
			if addon_data.hunter.is_spell_aimed_shot(spell_id) then

				addon_data.hunter.FeignDeath()
			end
            if addon_data.hunter.is_spell_auto_shot(spell_id) or addon_data.hunter.is_spell_shoot(spell_id) then
				addon_data.hunter.FeignFullReset = false
                addon_data.hunter.last_shot_time = GetTime()
                addon_data.hunter.ResetShotTimer()
			else 
                addon_data.hunter.casting_auto = false
            end
			if addon_data.hunter.is_spell_shoot(spell_id) then
				new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")
				addon_data.hunter.range_speed = new_range_speed
			end
        end

		if addon_data.hunter.is_spell_auto_shot(spell_id) then	-- Update the ranged attack speed
			new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")

			-- Handling for getting haste buffs in combat, don't need to update auto shot cast time until the next shot is ready
			if new_range_speed ~= addon_data.hunter.range_speed then
				if not addon_data.hunter.auto_shot_ready then
					addon_data.hunter.shot_timer = addon_data.hunter.shot_timer * 
											(new_range_speed / addon_data.hunter.range_speed)
				end
				addon_data.hunter.range_speed = new_range_speed
				addon_data.hunter.range_auto_speed_modified = addon_data.hunter.range_cast_speed_modifer
			end
		end
    end
end

addon_data.hunter.OnUnitSpellCastInterrupted = function(unit, spell_id)
    local settings = character_castbar_settings
	
	addon_data.hunter.casting = false
	if unit == 'player' and addon_data.hunter.is_spell_auto_shot(spell_id) then
		addon_data.hunter.casting_auto = false
		addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
		addon_data.hunter.ResetShotTimer()
	end
	
end

--- triggered when auto shot is toggled on and attempts to begin casting, but can't
--- This causes 0.5 seconds of delay before it can try casting again
addon_data.hunter.OnUnitSpellCastFailedQuiet = function(unit, spell_id)
    local settings = character_hunter_settings
	local curr_time = GetTime()
    if settings.show_autoshot_delay_timer and unit == "player" and addon_data.hunter.is_spell_auto_shot(spell_id) then
        
		if not addon_data.hunter.casting and addon_data.hunter.shooting 
		   and (curr_time - addon_data.hunter.last_shot_time) > (addon_data.hunter.range_speed - addon_data.hunter.auto_cast_time) then
			
			addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time + 0.5
		end
    end
end

--- Updating and initializing visuals
--- ---------------------------------
addon_data.hunter.UpdateVisualsOnUpdate = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
    local range_speed = addon_data.hunter.range_speed
    local shot_timer = addon_data.hunter.shot_timer
    local auto_cast_time = addon_data.hunter.auto_cast_time
	local mult_cast_time = 0.35 * addon_data.hunter.range_cast_speed_modifer
	
	if settings.enabled then
        frame.shot_bar_text:SetText(tostring(addon_data.utils.SimpleRound(shot_timer, 0.1)))
        if addon_data.core.in_combat or addon_data.hunter.shooting or addon_data.hunter.casting_shot then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end
        if not settings.one_bar then
            if addon_data.hunter.auto_shot_ready then
                frame.shot_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
                new_width = settings.width * (auto_cast_time - shot_timer) / auto_cast_time
                frame.multishot_clip_bar:Hide()
            else
                frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
                new_width = settings.width * ((shot_timer - auto_cast_time) / (range_speed - auto_cast_time))
                if settings.show_multishot_clip_bar then
                    frame.multishot_clip_bar:Show()
                    multishot_clip_width = math.min((settings.width * 2) * (mult_cast_time / (addon_data.hunter.range_speed - mult_cast_time)), settings.width)
                    frame.multishot_clip_bar:SetWidth(multishot_clip_width)
                end
            end
            if new_width < 2 then
                new_width = 2
            end
            frame.shot_bar:SetWidth(math.min(new_width, settings.width))
        else
            timer_width = settings.width * ((addon_data.hunter.range_speed - addon_data.hunter.shot_timer) / addon_data.hunter.range_speed)
            if addon_data.hunter.auto_shot_ready then
                auto_shot_cast_width = settings.width * (addon_data.hunter.shot_timer / addon_data.hunter.range_speed)
            else
                auto_shot_cast_width = settings.width * (addon_data.hunter.auto_cast_time / addon_data.hunter.range_speed)
            end
            if settings.show_multishot_clip_bar then
                frame.multishot_clip_bar:Show()
                multishot_clip_width = math.min(settings.width * (mult_cast_time / (addon_data.hunter.range_speed - mult_cast_time)), settings.width)
                frame.multishot_clip_bar:SetWidth(5)
                multi_offset = (settings.width * (addon_data.hunter.auto_cast_time / addon_data.hunter.range_speed)) + multishot_clip_width
                frame.multishot_clip_bar:SetPoint('BOTTOMRIGHT', -multi_offset, 0)
            end
            frame.shot_bar:SetWidth(math.min(timer_width, settings.width))
            frame.auto_shot_cast_bar:SetWidth(math.max(auto_shot_cast_width, 0.001))
        end
		frame:SetSize(settings.width, settings.height)
    end
end

addon_data.hunter.UpdateVisualsOnSettingsChange = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
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
        frame.shot_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.shot_bar:SetPoint("BOTTOM", 0, 0)
            frame.auto_shot_cast_bar:Hide()
        else
            frame.shot_bar:SetPoint("BOTTOMLEFT", 0, 0)
            frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
            frame.auto_shot_cast_bar:Show()
            frame.auto_shot_cast_bar:SetPoint('BOTTOMRIGHT', 0, 0)
            frame.auto_shot_cast_bar:SetHeight(settings.height)
            frame.auto_shot_cast_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
        end
        frame.shot_bar_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - (settings.fontsize / 2))
        frame.shot_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
		frame.shot_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
		
        frame.shot_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.shot_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
            frame.auto_shot_cast_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.shot_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
            frame.auto_shot_cast_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.multishot_clip_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.multishot_clip_bar:SetPoint("BOTTOM", 0, 0)
        else
            frame.multishot_clip_bar:SetPoint("BOTTOMRIGHT", 0, 0)
        end
        frame.multishot_clip_bar:SetHeight(settings.height)
        frame.multishot_clip_bar:SetColorTexture(settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
		
        if settings.show_multishot_clip_bar then
            frame.multishot_clip_bar:Show()
        else
            frame.multishot_clip_bar:Hide()
        end
        if settings.show_text then
            frame.shot_bar_text:Show()
        else
            frame.shot_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

addon_data.hunter.OnFrameDragStart = function()
    if not character_hunter_settings.is_locked then
        addon_data.hunter.frame:StartMoving()
    end
end

addon_data.hunter.OnFrameDragStop = function()
    local frame = addon_data.hunter.frame
    local settings = character_hunter_settings
    frame:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateConfigPanelValues()
end

addon_data.hunter.InitializeVisuals = function()
    local settings = character_hunter_settings
    -- Create the frame
    addon_data.hunter.frame = CreateFrame("Frame", addon_name .. "HunterAutoshotFrame", UIParent)
    local frame = addon_data.hunter.frame
	
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.hunter.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.hunter.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint('TOPLEFT', -9, 9)
    frame.backplane:SetPoint('BOTTOMRIGHT', 9, -9)
    frame.backplane:SetFrameStrata('BACKGROUND')
    -- Create the shot bar
    frame.shot_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the shot bar text
    frame.shot_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.shot_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.shot_bar_text:SetJustifyV("CENTER")
    frame.shot_bar_text:SetJustifyH("CENTER")
    -- Create the multishot clip bar
    frame.multishot_clip_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Create the auto shot cast bar indicator
    frame.auto_shot_cast_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Show it off
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnUpdate()
    frame:Show()
end



--- Everything below is designated as part of the UI settings menu. Checkboxes, adjustments, sliders
--- ------------------------------------------------------------------------------------------------
--- Adjusts the values of everything based on the settings selected with UpdateConfigPanelValues
--- 10 boxes that can be checked, all exact same just with different names
--- Bar height, width, and offset values set with numerical value
--- Color picker selection for 3 visual displays of the bars
--- Alpha adjustments for 3 visual displays of the bars
addon_data.hunter.UpdateConfigPanelValues = function()
    local panel = addon_data.hunter.config_frame
    local settings = character_hunter_settings
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_multishot_clip_bar_checkbox:SetChecked(settings.show_multishot_clip_bar)
	panel.show_autoshot_delay_checkbox:SetChecked(settings.show_autoshot_delay_timer)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
    panel.one_bar_checkbox:SetChecked(settings.one_bar)
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
    panel.cooldown_color_picker.foreground:SetColorTexture(
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
    panel.autoshot_cast_color_picker.foreground:SetColorTexture(
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
    panel.multi_clip_color_picker.foreground:SetColorTexture(
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
        
    if settings.one_bar then
        panel.explaination:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterOneBarExplainedAlpha')
        panel.explaination:SetSize(350, 175)
        panel.explaination:SetPoint('TOPLEFT', -50, -385)
    else
        panel.explaination:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterBarExplainedFullAlpha')
        panel.explaination:SetSize(700, 175)
        panel.explaination:SetPoint('TOPLEFT', -48, -410)
    end
    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

addon_data.hunter.EnabledCheckBoxOnClick = function(self)
    character_hunter_settings.enabled = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowMultiShotClipBarCheckBoxOnClick = function(self)
   character_hunter_settings.show_multishot_clip_bar = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowAutoShotDelayCheckBoxOnClick = function(self)
   character_hunter_settings.show_autoshot_delay_timer = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowBorderCheckBoxOnClick = function(self)
    character_hunter_settings.show_border = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ClassicBarsCheckBoxOnClick = function(self)
    character_hunter_settings.classic_bars = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.OneBarCheckBoxOnClick = function(self)
    character_hunter_settings.one_bar = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateConfigPanelValues()
end

addon_data.hunter.ShowTextCheckBoxOnClick = function(self)
    character_hunter_settings.show_text = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.WidthEditBoxOnEnter = function(self)
    character_hunter_settings.width = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.HeightEditBoxOnEnter = function(self)
    character_hunter_settings.height = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.FontSizeEditBoxOnEnter = function(self)
    character_hunter_settings.fontsize = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.XOffsetEditBoxOnEnter = function(self)
    character_hunter_settings.x_offset = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.YOffsetEditBoxOnEnter = function(self)
    character_hunter_settings.y_offset = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.CooldownColorPickerOnClick = function()
    local settings = character_hunter_settings
    local function CooldownOnActionFunc(restore)
        local settings = character_hunter_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a = new_r, new_g, new_b, new_a
        addon_data.hunter.config_frame.cooldown_color_picker.foreground:SetColorTexture(
            settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
        addon_data.hunter.UpdateVisualsOnSettingsChange()
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        CooldownOnActionFunc, CooldownOnActionFunc, CooldownOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.cooldown_a
    ColorPickerFrame:SetColorRGB(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b)
    ColorPickerFrame.previousValues = {settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a}
    ColorPickerFrame:Show()
end

addon_data.hunter.AutoShotCastColorPickerOnClick = function()
    local settings = character_hunter_settings
    local function AutoShotCastOnActionFunc(restore)
        local settings = character_hunter_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a = new_r, new_g, new_b, new_a
        addon_data.hunter.config_frame.autoshot_cast_color_picker.foreground:SetColorTexture(
            settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
        addon_data.hunter.UpdateVisualsOnSettingsChange()
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        AutoShotCastOnActionFunc, AutoShotCastOnActionFunc, AutoShotCastOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.auto_cast_a
    ColorPickerFrame:SetColorRGB(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b)
    ColorPickerFrame.previousValues = {settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a}
    ColorPickerFrame:Show()
end

addon_data.hunter.MultiClipColorPickerOnClick = function()
    local settings = character_hunter_settings
    local function MultiClipOnActionFunc(restore)
        local settings = character_hunter_settings
        local new_r, new_g, new_b, new_a
        if restore then
            new_r, new_g, new_b, new_a = unpack(restore)
        else
            new_a, new_r, new_g, new_b = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
        end
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a = new_r, new_g, new_b, new_a
        addon_data.hunter.frame.multishot_clip_bar:SetColorTexture(settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
        addon_data.hunter.config_frame.multi_clip_color_picker.foreground:SetColorTexture(
            settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
        MultiClipOnActionFunc, MultiClipOnActionFunc, MultiClipOnActionFunc
    ColorPickerFrame.hasOpacity = true 
    ColorPickerFrame.opacity = 1 - settings.clip_a
    ColorPickerFrame:SetColorRGB(settings.clip_r, settings.clip_g, settings.clip_b)
    ColorPickerFrame.previousValues = {settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a}
    ColorPickerFrame:Show()
end

addon_data.hunter.CombatAlphaOnValChange = function(self)
    character_hunter_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.OOCAlphaOnValChange = function(self)
    character_hunter_settings.ooc_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.BackplaneAlphaOnValChange = function(self)
    character_hunter_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end
--- Initializes the main setting panel including layout, alignment, and design
addon_data.hunter.CreateConfigPanel = function(parent_panel)
    addon_data.hunter.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = addon_data.hunter.config_frame
    local settings = character_hunter_settings
    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L["Hunter & Wand Shot Bar Settings"], 20)
    panel.title_text:SetPoint("TOPLEFT", 10 , -10)
    panel.title_text:SetTextColor(1, 0.9, 0, 1)
    
    -- General Settings Text
    panel.general_text = addon_data.config.TextFactory(panel, L["General Settings"], 16)
    panel.general_text:SetPoint("TOPLEFT", 10 , -50)
    panel.general_text:SetTextColor(1, 0.9, 0, 1)
    
    -- Enabled Checkbox
    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "HunterEnabledCheckBox",
        panel,
        L["Enable"],
        L["Enables the Autoshot/Shoot bars."],
        addon_data.hunter.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -70)
    
    -- Show Border Checkbox
    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowBorderCheckBox",
        panel,
        L["Show border"],
        L["Enables the shot bar's border."],
        addon_data.hunter.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -90)
    
    -- Show Classic Bars Checkbox
    panel.classic_bars_checkbox = addon_data.config.CheckBoxFactory(
        "HunterClassicBarsCheckBox",
        panel,
        L["Classic bars"],
        L["Enables the classic texture for the shot bars."],
        addon_data.hunter.ClassicBarsCheckBoxOnClick)
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -110)
    
    -- One bar Checkbox
    panel.one_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterOneBarCheckBox",
        panel,
        L["YaHT / One bar"],
        L["Changes the Auto Shot bar to a single bar that fills from left to right"],
        addon_data.hunter.OneBarCheckBoxOnClick)
    panel.one_bar_checkbox:SetPoint("TOPLEFT", 10, -130)
    
    -- Show Text Checkbox
    panel.show_text_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowTextCheckBox",
        panel,
        L["Show Text"],
        L["Enables the shot bar text."],
        addon_data.hunter.ShowTextCheckBoxOnClick)
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -150)
    
    -- Width EditBox
    panel.width_editbox = addon_data.config.EditBoxFactory(
        "HunterWidthEditBox",
        panel,
        L["Bar Width"],
        75,
        25,
        addon_data.hunter.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -90, "BOTTOMRIGHT", 275, -115)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "HunterHeightEditBox",
        panel,
        L["Bar Height"],
        75,
        25,
        addon_data.hunter.HeightEditBoxOnEnter)
	panel.height_editbox:SetPoint("TOPLEFT", 320, -90, "BOTTOMRIGHT", 225, -115)
	-- Font Size EditBox
	panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        addon_data.hunter.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterXOffsetEditBox",
        panel,
        L["X Offset"],
        75,
        25,
        addon_data.hunter.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -140, "BOTTOMRIGHT", 275, -165)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterYOffsetEditBox",
        panel,
        L["Y Offset"],
        75,
        25,
        addon_data.hunter.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -140, "BOTTOMRIGHT", 225, -165)
    
    -- Cooldown color picker
    panel.cooldown_color_picker = addon_data.config.color_picker_factory(
        'HunterCooldownColorPicker',
        panel,
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a,
        L["Auto Shot Cooldown Color"],
        addon_data.hunter.CooldownColorPickerOnClick)
    panel.cooldown_color_picker:SetPoint('TOPLEFT', 205, -180)
    
    -- Autoshot cast color picker
    panel.autoshot_cast_color_picker = addon_data.config.color_picker_factory(
        'HunterAutoShotCastColorPicker',
        panel,
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a,
        L["Auto Shot Cast Color"],
        addon_data.hunter.AutoShotCastColorPickerOnClick)
    panel.autoshot_cast_color_picker:SetPoint('TOPLEFT', 205, -200)
    
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "HunterInCombatAlphaSlider",
        panel,
        L["In Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -90)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "HunterOOCAlphaSlider",
        panel,
        L["Out of Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "HunterBackplaneAlphaSlider",
        panel,
        L["Backplane Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -190)
    
    -- Hunter Specific Settings Text
    panel.hunter_text = addon_data.config.TextFactory(panel, L["Hunter Specific Settings"], 16)
    panel.hunter_text:SetPoint("TOPLEFT", 10 , -220)
    panel.hunter_text:SetTextColor(1, 0.9, 0, 1)

    -- Show Multi-Shot Clip Bar Checkbox
    panel.show_multishot_clip_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowMultiShotClipBarCheckBox",
        panel,
        L["Multi-Shot clip bar"],
        L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."],
        addon_data.hunter.ShowMultiShotClipBarCheckBoxOnClick)
    panel.show_multishot_clip_bar_checkbox:SetPoint("TOPLEFT", 10, -220)
    
    -- Show Autoshot delay timer Checkbox
    panel.show_autoshot_delay_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowAutoShotDelayCheckBox",
        panel,
        L["Auto Shot delay timer"],
        L["Shows a timer that represents when Auto shot is delayed."],
        addon_data.hunter.ShowAutoShotDelayCheckBoxOnClick)
    panel.show_autoshot_delay_checkbox:SetPoint("TOPLEFT", 10, -240)
    
    -- Multi-shot clip color picker
    panel.multi_clip_color_picker = addon_data.config.color_picker_factory(
        'HunterMultiClipColorPicker',
        panel,
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a,
        L["Multi-Shot Clip Color"],
        addon_data.hunter.MultiClipColorPickerOnClick)
    panel.multi_clip_color_picker:SetPoint('TOPLEFT', 205, -240)
    
    -- Add the explaination text
    panel.explaination_text = addon_data.config.TextFactory(panel, L["Bar Explanation"], 16)
    panel.explaination_text:SetPoint("TOPLEFT", 10 , -400)
    panel.explaination_text:SetTextColor(1, 0.9, 0, 1)
    
    -- Add the explaination
    panel.explaination = panel:CreateTexture(nil, 'ARTWORK')
    
    -- Return the final panel
    addon_data.hunter.UpdateConfigPanelValues()
    return panel
end
