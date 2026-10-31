local addon_name, addon_data = ...
local L = addon_data.localization_table

--- define addon structure from the above local variable
addon_data.hunter = {}

-- WoW Forever / 12.x: protected unit stats may be returned as secret values.
-- Secret values cannot be compared, stringified, or used in arithmetic by addon code.
local function WST_IsSecret(value)
    return issecretvalue and issecretvalue(value)
end
--- declare array for ranks of all abilities, cast times, cooldown, based on spell ID
addon_data.hunter.shot_spell_ids = {
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
	[27021] = {spell_name = L["Multi-Shot"], rank = 6, cast_time = 0.45, cooldown = 10},
    [19434] = {spell_name = L["Aimed Shot"], rank = 1, cast_time = 3, cooldown = 6},
    [20900] = {spell_name = L["Aimed Shot"], rank = 2, cast_time = 3, cooldown = 6},
    [20901] = {spell_name = L["Aimed Shot"], rank = 3, cast_time = 3, cooldown = 6},
    [20902] = {spell_name = L["Aimed Shot"], rank = 4, cast_time = 3, cooldown = 6},
    [20903] = {spell_name = L["Aimed Shot"], rank = 5, cast_time = 3, cooldown = 6},
    [20904] = {spell_name = L["Aimed Shot"], rank = 6, cast_time = 3, cooldown = 6},
	[27065] = {spell_name = L["Aimed Shot"], rank = 7, cast_time = 3, cooldown = 6},
    [5019] = {spell_name = L["Shoot"], rank = nil, cast_time = nil, cooldown = nil}
}
--- is spell multi-shot defined by spell_id
addon_data.hunter.is_spell_multi_shot = function(spell_id)
    if (spell_id == 2643) or (spell_id == 14288) or (spell_id == 14289) or 
       (spell_id == 14290) or (spell_id == 25294) or (spell_id == 27021) then
            return true
    else
            return false
    end
end
--- is spell aimed shot defined by spell_id
addon_data.hunter.is_spell_aimed_shot = function(spell_id)
    if (spell_id == 19434) or (spell_id == 20900) or (spell_id == 20901) or 
       (spell_id == 20902) or (spell_id == 20903) or (spell_id == 20904) or (spell_id == 27065) then
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
addon_data.hunter.shot_timer = 0.5
addon_data.hunter.last_shot_time = GetTime()
addon_data.hunter.auto_shot_ready = true
addon_data.hunter.auto_cast_active = false

-- Forever retry-delay indicator. This is intentionally separate from
-- shot_timer so a failed Auto Shot attempt cannot reset the real swing timer.
addon_data.hunter.auto_delay_duration = 0.5
addon_data.hunter.auto_delay_timer = 0
addon_data.hunter.FeignStatus = false
addon_data.hunter.FeignFullReset = false
addon_data.hunter.range_auto_speed_modified = 1
addon_data.hunter.base_speed = 1
addon_data.hunter.spell_GCD = 0
addon_data.hunter.spell_GCD_Time = 0

addon_data.hunter.casting = false

addon_data.hunter.has_moved = false

-- Auto Shot's visual windup uses ranged weapon haste, including quiver haste.
addon_data.hunter.GetAutoCastTime = function()
    -- This cycle's native speed is authoritative and stays fixed mid-cycle.
    if addon_data.hunter.native_cycle_cast_time then return addon_data.hunter.native_cycle_cast_time end
    local base = tonumber(addon_data.hunter.base_speed) or 0
    -- Inventory-change events may not have fired yet after login/reload.
    if base <= 1 and addon_data.GetRangedBaseSpeed then
        local value = addon_data.GetRangedBaseSpeed()
        if not WST_IsSecret(value) then
            local parsed = tonumber(value)
            if parsed and parsed > 1 then
                base = parsed
                addon_data.hunter.base_speed = base
            end
        end
    end
    local speed = UnitRangedDamage("player")
    if not WST_IsSecret(speed) and type(speed) == "number" and speed > 0 and base > 1 then
        -- Includes every ranged speed modifier reflected in actual attack speed.
        local cast_time = 0.5 * speed / base
        addon_data.hunter.cached_auto_cast_time = cast_time
        return cast_time
    end
    -- Combat may hide ranged stats. Never replace a known speed multiplier
    -- with the haste API's zero/default value merely because stats vanished.
    if addon_data.hunter.cached_auto_cast_time then
        return addon_data.hunter.cached_auto_cast_time
    end
    local haste = GetRangedHaste and GetRangedHaste()
    if not WST_IsSecret(haste) and type(haste) == "number" and haste > -100 then
        return 0.5 / (1 + haste / 100)
    end
    return 0.5
end

-- Preserve known readiness when combat makes a later API read unavailable.
addon_data.hunter.auto_visual_state = {}
addon_data.hunter.UpdateAutoMovement = function()
    local state = addon_data.hunter.auto_visual_state
    local speed = GetUnitSpeed("player")
    if not WST_IsSecret(speed) and type(speed) == "number" then
        state.moving = speed > 0
    elseif state.move_pending_since and GetTime() - state.move_pending_since >= 0.05 then
        -- Short event pulses are not enough to declare movement when speed
        -- cannot be read. A sustained start event still cancels the inference.
        state.moving = true
    end
    return state.moving
end

addon_data.hunter.OnReadinessEvent = function(_, event)
    local state = addon_data.hunter.auto_visual_state
    if event == "PLAYER_STARTED_MOVING" then
        state.move_pending_since = state.move_pending_since or GetTime()
        if addon_data.hunter.UpdateAutoMovement() == true and addon_data.hunter.auto_cast_inferred then
            addon_data.hunter.auto_cast_active = false
            addon_data.hunter.auto_cast_inferred = false
        end
    elseif event == "PLAYER_STOPPED_MOVING" then
        state.move_pending_since = nil
        state.moving = false
        addon_data.hunter.UpdateAutoMovement()
    else
        addon_data.hunter.pending_auto_attempt = nil
        addon_data.hunter.auto_cast_guid = nil
        state.attackable, state.in_range, state.dead = nil, nil, nil
        if event == "PLAYER_ENTERING_WORLD" then state.move_pending_since = nil end
        if addon_data.hunter.auto_cast_inferred then
            addon_data.hunter.auto_cast_active = false
            addon_data.hunter.auto_cast_inferred = false
        end
    end
end

addon_data.hunter.CanBeginAutoVisual = function()
    local state = addon_data.hunter.auto_visual_state
    if not addon_data.hunter.shooting or not UnitExists("target") then return false end
    addon_data.hunter.UpdateAutoMovement()
    local dead = UnitIsDeadOrGhost("target")
    if not WST_IsSecret(dead) and type(dead) == "boolean" then state.dead = dead end
    local attackable = UnitCanAttack("player", "target")
    if not WST_IsSecret(attackable) and type(attackable) == "boolean" then
        state.attackable = attackable
    end
    local checked_range = false
    if C_SwingTimer and C_SwingTimer.IsTargetWithinSwingRange and
       Enum and Enum.PlayerSwingType and Enum.PlayerSwingType.Ranged then
        local ok, value = pcall(C_SwingTimer.IsTargetWithinSwingRange, Enum.PlayerSwingType.Ranged)
        if ok and not WST_IsSecret(value) and value ~= nil then
            state.in_range = value == true or value == 1
            checked_range = true
        end
    end
    if not checked_range and addon_data.range and addon_data.range.GetRangeBand then
        local ok, _, key = pcall(addon_data.range.GetRangeBand)
        if ok then
            if key == "ranged" or key == "close" then
                state.in_range = true
            elseif key == "melee" or key == "deadzone" or key == "far" or key == "out" then
                state.in_range = false
            end
        end
    end
    return state.moving == false and state.dead ~= true and
        state.attackable == true and state.in_range == true
end

-- handling of stopping auto timer from starting
addon_data.hunter.StartCastingSpell = function(spell_id)
    if not spell_id or addon_data.hunter.casting then
        return
    end

    if not UnitCanAttack("player", "target") then
        return
    end

    -- Other cast-time shots also control the general casting state.
    if addon_data.hunter.is_spell_multi_shot(spell_id) or
       addon_data.hunter.is_spell_aimed_shot(spell_id) or
       spell_id == 34120 then -- Steady Shot
        addon_data.hunter.casting = true
    end
end

addon_data.hunter.LoadSettings = function()
    -- Ensure the alias is pointing at the current profile table
    character_hunter_settings = addon_data.db.profile.hunter

    for setting, value in pairs(addon_data.hunter.default_settings) do
        if character_hunter_settings[setting] == nil then
            character_hunter_settings[setting] = value
        end
    end
        if character_hunter_settings.enabled == nil then
        local _, class = UnitClass("player")
        character_hunter_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    end
    
    -- One-time tooltip initialize
    if not addon_data.hunter.scan_tip then
        addon_data.hunter.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
        addon_data.hunter.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

-- WoW Forever native ranged swing timing.
-- In Forever, PLAYER_SWING is the authoritative source for ranged swing
-- timing. Spell-cast events do not reset the normal Auto Shot timer.
addon_data.hunter.OnPlayerSwing = function(duration, swing_type)
    if not duration or WST_IsSecret(duration) or duration <= 0 then
        return
    end

    if not Enum or not Enum.PlayerSwingType or
       swing_type ~= Enum.PlayerSwingType.Ranged then
        return
    end

    if addon_data.hunter.auto_cast_inferred and
       (not addon_data.hunter.auto_cast_guid or addon_data.hunter.auto_cast_guid == addon_data.hunter.last_auto_success_guid) then
        addon_data.hunter.auto_cast_active = false
        addon_data.hunter.auto_cast_inferred = false
        addon_data.hunter.auto_cast_remaining = 0
    end
    local base = tonumber(addon_data.hunter.base_speed) or 0
    if base <= 1 then
        addon_data.hunter.GetAutoCastTime() -- resolve the base speed if not loaded yet
        base = tonumber(addon_data.hunter.base_speed) or 0
    end
    addon_data.hunter.native_cycle_speed = duration
    if base > 1 then
        addon_data.hunter.native_cycle_cast_time = 0.5 * duration / base
        addon_data.hunter.cached_auto_cast_time = addon_data.hunter.native_cycle_cast_time
    end
    addon_data.hunter.range_speed = duration
    addon_data.hunter.last_shot_time = GetTime()
    addon_data.hunter.shot_timer = duration
    addon_data.hunter.auto_shot_ready = false
    addon_data.hunter.FeignFullReset = false
end

-- Replaced update info with this instead, checking weapon id every time inventory is changed for simplicity
addon_data.hunter.OnInventoryChange = function()
    local _, class, _ = UnitClass("player")
    if (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK") then
        local base_speed = addon_data.GetRangedBaseSpeed()
        if not WST_IsSecret(base_speed) then
            base_speed = tonumber(base_speed)
        end
        if base_speed then
            addon_data.hunter.base_speed = base_speed
        end
    end
end

--- Reset Swing Timer unhasted separately due to feign and other spells
addon_data.hunter.FeignDeath = function()
    addon_data.hunter.last_shot_time = GetTime()
	if not addon_data.hunter.FeignFullReset then
		local base_speed = addon_data.GetRangedBaseSpeed()
        if not WST_IsSecret(base_speed) and base_speed then
            addon_data.hunter.range_speed = base_speed + 0.15
        end
		addon_data.hunter.FeignFullReset = true
	end
    addon_data.hunter.ResetShotTimer()
end

--- Update the native ranged swing countdown.
addon_data.hunter.ResetShotTimer = function()
    addon_data.hunter.pending_auto_attempt = nil
    addon_data.hunter.auto_cast_guid = nil
    addon_data.hunter.auto_cast_active = false
    addon_data.hunter.auto_cast_inferred = false
        addon_data.hunter.shot_timer = tonumber(addon_data.hunter.range_speed) or 0
    addon_data.hunter.auto_shot_ready = false
end

-- A cast phase has one deadline. Event arrival/frame length must not rewind it.
addon_data.hunter.BeginAutoCastVisual = function(duration, started_at, guid, inferred)
    local h = addon_data.hunter
    if h.auto_cast_active then
        if not h.auto_cast_guid and guid then h.auto_cast_guid = guid end
        if not inferred then h.auto_cast_inferred = false end
        return
    end
    h.auto_cast_active = true
    h.auto_cast_inferred = inferred
    h.auto_cast_guid = guid
    h.auto_cast_duration = duration
    h.auto_cast_started_at = started_at
    h.auto_cast_ends_at = started_at + duration
    h.auto_cast_remaining = math.max(0, h.auto_cast_ends_at - GetTime())
    local speed = UnitRangedDamage("player")
    if WST_IsSecret(speed) or type(speed) ~= "number" or speed <= 0 then
        speed = h.visual_range_speed or h.range_speed
    end
    h.auto_cast_visual_speed = h.native_cycle_speed or speed
end

addon_data.hunter.UpdateAutoShotTimer = function(elapsed)
    local curr_time = GetTime()
    local shot_timer = tonumber(addon_data.hunter.shot_timer) or 0

    local cast_time = addon_data.hunter.GetAutoCastTime()
    addon_data.hunter.shot_timer = math.max(shot_timer - elapsed, cast_time)
    local retry = tonumber(addon_data.hunter.auto_delay_timer) or 0
    local can_begin = addon_data.hunter.CanBeginAutoVisual()
    if addon_data.hunter.auto_cast_inferred and not can_begin then
        addon_data.hunter.auto_cast_active = false
        addon_data.hunter.auto_cast_inferred = false
    end
    if addon_data.hunter.auto_cast_active then
        addon_data.hunter.auto_cast_remaining = math.max(
            (addon_data.hunter.auto_cast_ends_at or curr_time) - curr_time, 0)
    elseif can_begin and not addon_data.hunter.pending_auto_attempt then
        local wait = math.max(0, shot_timer - cast_time, retry)
        if elapsed >= wait then
            local started_at = math.max(curr_time - elapsed + wait,
                addon_data.hunter.autorepeat_started_at or (curr_time - elapsed))
            addon_data.hunter.BeginAutoCastVisual(cast_time, started_at, nil, true)
        end
    end
    addon_data.hunter.auto_shot_ready = not addon_data.hunter.auto_cast_active and
        addon_data.hunter.shot_timer <= cast_time

    local auto_delay_timer = tonumber(addon_data.hunter.auto_delay_timer) or 0
    if auto_delay_timer > 0 then
        addon_data.hunter.auto_delay_timer = math.max(auto_delay_timer - elapsed, 0)
    end

    local pending = addon_data.hunter.pending_auto_attempt
    if pending and curr_time > pending.sent_at then
        addon_data.hunter.pending_auto_attempt = nil
        if addon_data.hunter.shooting and can_begin then
            addon_data.hunter.BeginAutoCastVisual(pending.cast_time, pending.sent_at, pending.guid, true)
            addon_data.hunter.auto_delay_timer = 0
        end
    end

    if addon_data.hunter.spell_GCD_Time + 1.5 > curr_time then
        addon_data.hunter.spell_GCD = 1.5 - (curr_time - addon_data.hunter.spell_GCD_Time)
    else
        addon_data.hunter.spell_GCD = 0
    end
end

addon_data.hunter.OnUpdate = function(elapsed)
    local settings = character_hunter_settings
    if settings.enabled then
        -- Check to see if we have moved
        local move_speed = GetUnitSpeed("player")
        if not WST_IsSecret(move_speed) then
            addon_data.hunter.has_moved = (move_speed > 0)
        end
		
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
    if not addon_data.hunter.shooting then
        addon_data.hunter.autorepeat_started_at = GetTime()
        if GetTime() - addon_data.hunter.last_shot_time >= addon_data.hunter.range_speed then
            addon_data.hunter.native_cycle_cast_time = nil
            addon_data.hunter.native_cycle_speed = nil
        end
    end
    -- Toggling autorepeat readies the cast segment but does not start its countdown.
    if not addon_data.hunter.shooting and
       addon_data.hunter.shot_timer <= 0.5 and
       addon_data.hunter.auto_delay_timer <= 0 then
        addon_data.hunter.shot_timer = addon_data.hunter.GetAutoCastTime()
        addon_data.hunter.auto_shot_ready = false
    end
    addon_data.hunter.shooting = true
    if addon_data.hunter.frame then
        addon_data.hunter.UpdateVisualsOnUpdate()
    end
end

addon_data.hunter.OnStopAutorepeatSpell = function()
    addon_data.hunter.shooting = false
    addon_data.hunter.pending_auto_attempt = nil
    addon_data.hunter.auto_cast_guid = nil
    addon_data.hunter.auto_cast_active = false
    addon_data.hunter.auto_cast_inferred = false
    addon_data.hunter.auto_delay_timer = 0
end

-- A SENT request is tentative until the current event batch has had a
-- chance to report FAILED_QUIET for the same GUID.
addon_data.hunter.OnUnitSpellCastSent = function(unit, target, cast_guid, spell_id)
    if unit ~= "player" or not addon_data.hunter.is_spell_auto_shot(spell_id) then return end
    if WST_IsSecret(cast_guid) or type(cast_guid) ~= "string" then return end
    if addon_data.hunter.auto_cast_active and addon_data.hunter.auto_cast_guid == cast_guid then return end
    local pending = addon_data.hunter.pending_auto_attempt
    if pending and pending.guid == cast_guid then return end
    addon_data.hunter.pending_auto_attempt = {
        guid = cast_guid, sent_at = GetTime(), cast_time = addon_data.hunter.GetAutoCastTime()
    }
end

-- Modern cast-start path. CLEU remains enabled, but UNIT_SPELLCAST_START gives
-- us a direct player cast event and fixes short casts such as Rank 1 Multi-Shot
-- being missed by the old combat-log-only start detection.
addon_data.hunter.OnUnitSpellCastStart = function(unit, spell_id, cast_guid)
    if unit ~= "player" or not spell_id then
        return
    end

    if addon_data.hunter.is_spell_auto_shot(spell_id) then
        addon_data.hunter.pending_auto_attempt = nil
        local guid = not WST_IsSecret(cast_guid) and cast_guid or nil
        addon_data.hunter.BeginAutoCastVisual(addon_data.hunter.GetAutoCastTime(), GetTime(), guid, false)
        addon_data.hunter.auto_delay_timer = 0
        addon_data.hunter.auto_shot_ready = false
    end
    addon_data.hunter.FeignStatus = false
    addon_data.hunter.StartCastingSpell(spell_id)

    if spell_id == 34120 or addon_data.hunter.is_spell_multi_shot(spell_id) then
        addon_data.hunter.spell_GCD = 1.5
        addon_data.hunter.spell_GCD_Time = GetTime()
    end
end
-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
addon_data.hunter.OnCombatLogUnfiltered = function()
    local _, event, _, casterID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()

	if casterID == UnitGUID("player") then
	
		if event == "SPELL_CAST_START" then
            addon_data.hunter.OnUnitSpellCastStart("player", spellID)
		return end

	end		
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
addon_data.hunter.OnUnitSpellCastSucceeded = function(unit, spell_id, cast_guid)
    if unit ~= "player" then
        return
    end

    if addon_data.hunter.is_spell_auto_shot(spell_id) then
        if WST_IsSecret(cast_guid) then cast_guid = nil end
        addon_data.hunter.last_auto_success_guid = cast_guid
        local pending = addon_data.hunter.pending_auto_attempt
        if pending and pending.guid == cast_guid then addon_data.hunter.pending_auto_attempt = nil end
        -- A completed shot confirms these prerequisites even if combat APIs
        -- cannot expose them. Readable negative checks still take priority.
        local state = addon_data.hunter.auto_visual_state
        state.attackable, state.in_range, state.dead = true, true, false
        if not cast_guid or not addon_data.hunter.auto_cast_guid or addon_data.hunter.auto_cast_guid == cast_guid then
            addon_data.hunter.auto_cast_active = false
            addon_data.hunter.auto_cast_inferred = false
            addon_data.hunter.auto_cast_remaining = 0
            addon_data.hunter.auto_cast_guid = nil
            addon_data.hunter.auto_delay_timer = 0
        end
    end

    addon_data.hunter.casting = false

    -- Forever/native mode:
    -- PLAYER_SWING is the sole authority for normal ranged swing resets.
    -- Instant shots such as Arcane Shot must not alter shot_timer here.
    if addon_data.core.native_swing_available then
        if spell_id == 5384 then -- Feign Death
            addon_data.hunter.FeignStatus = true
            addon_data.hunter.FeignFullReset = false
        end
        return
    end

    -- Legacy compatibility path for clients without PLAYER_SWING.
    if not addon_data.hunter.shot_spell_ids[spell_id] then
        return
    end

    local spell_name = addon_data.hunter.shot_spell_ids[spell_id].spell_name

    if spell_name == L["Feign Death"] or spell_name == L["Trueshot Aura"] then
        if spell_name == L["Feign Death"] then
            addon_data.hunter.FeignStatus = true
        end
        addon_data.hunter.FeignDeath()
        return
    end

    if addon_data.hunter.is_spell_aimed_shot(spell_id) then
        addon_data.hunter.FeignFullReset = false
        addon_data.hunter.last_shot_time = GetTime()
        addon_data.hunter.ResetShotTimer()
    end

    if addon_data.hunter.is_spell_auto_shot(spell_id) or
       addon_data.hunter.is_spell_shoot(spell_id) then
        addon_data.hunter.FeignFullReset = false
        addon_data.hunter.last_shot_time = GetTime()
        addon_data.hunter.ResetShotTimer()
    end

    if addon_data.hunter.is_spell_shoot(spell_id) then
        local new_range_speed = UnitRangedDamage("player")
        if not WST_IsSecret(new_range_speed) and
           new_range_speed and new_range_speed ~= 0 then
            addon_data.hunter.range_speed = new_range_speed
        end
    end
end

addon_data.hunter.OnUnitSpellCastInterrupted = function(unit, spell_id, cast_guid)
    if unit ~= "player" then return end
    if addon_data.hunter.is_spell_auto_shot(spell_id) then
        if WST_IsSecret(cast_guid) then cast_guid = nil end
        local pending = addon_data.hunter.pending_auto_attempt
        if pending and (not cast_guid or pending.guid == cast_guid) then addon_data.hunter.pending_auto_attempt = nil end
        if not cast_guid or not addon_data.hunter.auto_cast_guid or addon_data.hunter.auto_cast_guid == cast_guid then
            addon_data.hunter.auto_cast_active = false
            addon_data.hunter.auto_cast_inferred = false
            addon_data.hunter.auto_cast_guid = nil
        end
    end
    addon_data.hunter.casting = false
end

--- triggered when auto shot is toggled on and attempts to begin casting, but can't
--- This causes 0.5 seconds of delay before it can try casting again
addon_data.hunter.OnUnitSpellCastFailedQuiet = function(unit, spell_id, cast_guid)
    local settings = character_hunter_settings

    if unit ~= "player" or
       not addon_data.hunter.is_spell_auto_shot(spell_id) then
        return
    end

    if WST_IsSecret(cast_guid) then cast_guid = nil end
    local pending = addon_data.hunter.pending_auto_attempt
    if pending and (not cast_guid or pending.guid == cast_guid) then addon_data.hunter.pending_auto_attempt = nil end
    -- An extra rejected request is not a failure to start the shot already
    -- underway. Leave that accepted cast and its display alone.
    if addon_data.hunter.auto_cast_active and cast_guid and addon_data.hunter.auto_cast_guid and
       addon_data.hunter.auto_cast_guid ~= cast_guid then
        return
    end
    -- Genuine failed starts always restart the full retry indicator, even
    -- when the native cooldown will cover some or all of that window.
    if not cast_guid or not addon_data.hunter.auto_cast_guid or addon_data.hunter.auto_cast_guid == cast_guid then
        addon_data.hunter.auto_cast_active = false
        addon_data.hunter.auto_cast_inferred = false
        addon_data.hunter.auto_cast_guid = nil
    end
    addon_data.hunter.auto_delay_timer = addon_data.hunter.auto_delay_duration
    addon_data.hunter.shot_timer = math.max(
        tonumber(addon_data.hunter.shot_timer) or 0,
        addon_data.hunter.GetAutoCastTime())
    if addon_data.hunter.frame then
        addon_data.hunter.UpdateVisualsOnUpdate()
    end
end

--- Updating and initializing visuals
--- ---------------------------------
addon_data.hunter.UpdateVisualsOnUpdate = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
    local range_speed = tonumber(addon_data.hunter.range_speed) or 1
    local shot_timer = tonumber(addon_data.hunter.shot_timer) or 0

    if range_speed <= 0 then
        range_speed = 1
    end

    if settings.enabled then
        if addon_data.hunter.auto_cast_active then
            shot_timer = addon_data.hunter.auto_cast_remaining or 0
        end
        local cast_time = addon_data.hunter.auto_cast_active and addon_data.hunter.auto_cast_duration or
            addon_data.hunter.GetAutoCastTime()
        local delay_timer = settings.show_autoshot_delay_timer and
            (tonumber(addon_data.hunter.auto_delay_timer) or 0) or 0
        local cast_remaining = addon_data.hunter.auto_cast_active and math.min(shot_timer, cast_time) or cast_time
        local displayed_timer = delay_timer > 0 and (cast_remaining + delay_timer) or shot_timer
        if not addon_data.hunter.shooting and shot_timer <= 0 then
            displayed_timer = cast_time
        end
        frame.shot_bar_text:SetText(string.format("%.1f", displayed_timer))

        if addon_data.core.in_combat or addon_data.hunter.shooting or addon_data.hunter.casting_shot then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end

        frame.shot_bar:SetVertexColor(
            settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
        -- Use weapon speed for the visual scale. PLAYER_SWING durations can
        -- include resets/delays and must not move the cast boundary.
        local weapon_speed = UnitRangedDamage("player")
        if WST_IsSecret(weapon_speed) or type(weapon_speed) ~= "number" or weapon_speed <= 0 then
            weapon_speed = addon_data.hunter.visual_range_speed or range_speed
        else
            addon_data.hunter.visual_range_speed = weapon_speed
        end
        if addon_data.hunter.native_cycle_speed then weapon_speed = addon_data.hunter.native_cycle_speed end
        if addon_data.hunter.auto_cast_active and addon_data.hunter.auto_cast_visual_speed then
            weapon_speed = addon_data.hunter.auto_cast_visual_speed
        end
        local scale = settings.width / math.max(weapon_speed, cast_time + addon_data.hunter.auto_delay_duration)
        local cast_width = cast_time * scale
        local retry_width = delay_timer * scale
        local cooldown_width = math.max(0, settings.width - cast_width)
        local progress = math.max(0, math.min(1, (range_speed - shot_timer) / range_speed))
        local white_width
        -- Autorepeat toggling/target loss does not reset the native cooldown.
        if settings.one_bar then
            -- Once the cast begins, white follows the shrinking red edge.
            local available_width = math.max(0, settings.width - cast_remaining * scale)
            white_width = math.min(available_width, settings.width * progress)
        else
            white_width = math.min(cooldown_width, math.max(0, shot_timer - cast_time) * scale)
        end
        frame.shot_bar:SetWidth(math.max(0.001, white_width))
        frame.shot_bar:SetShown(white_width > 0)

        frame.auto_shot_cast_bar:ClearAllPoints()
        frame.auto_shot_cast_bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.auto_shot_cast_bar:SetWidth(math.max(0.001, cast_remaining * scale))
        frame.auto_shot_cast_bar:SetShown(cast_remaining > 0)
        frame.retry_bar:ClearAllPoints()
        -- Retry always ends at the fixed START of the full cast segment.
        frame.retry_bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -cast_width, 0)
        frame.retry_bar:SetSize(math.max(0.001, retry_width), settings.height)
        frame.retry_bar:SetShown(delay_timer > 0)

        frame.multishot_clip_bar:Hide()

        frame:SetSize(settings.width, settings.height)
    end
end

addon_data.hunter.UpdateVisualsOnSettingsChange = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
	if settings.enabled then
        frame:EnableMouse(not settings.is_locked)
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
            frame.shot_bar:SetPoint("BOTTOMLEFT", 0, 0)
        else
            frame.shot_bar:SetPoint("BOTTOMLEFT", 0, 0)
            frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
        end
        frame.auto_shot_cast_bar:ClearAllPoints()
        -- Cast and retry segments count down toward the right edge.
        frame.auto_shot_cast_bar:SetPoint("BOTTOMRIGHT", 0, 0)
        frame.auto_shot_cast_bar:SetHeight(settings.height)
        frame.auto_shot_cast_bar:SetVertexColor(
            settings.auto_cast_r, settings.auto_cast_g,
            settings.auto_cast_b, settings.auto_cast_a)
        frame.auto_shot_cast_bar:Hide()
        frame.multishot_clip_bar:Hide()
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
        frame.auto_shot_cast_bar:Hide()
        frame.multishot_clip_bar:Hide()

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
    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
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
    frame.shot_bar_text:SetJustifyV("MIDDLE")
    frame.shot_bar_text:SetJustifyH("CENTER")
    -- Create the multishot clip bar
    frame.multishot_clip_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Create the auto shot cast bar indicator
    frame.auto_shot_cast_bar = frame:CreateTexture(nil,"OVERLAY")
    frame.retry_bar = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.retry_bar:SetColorTexture(1, 0.5, 0, 1)
    if not addon_data.hunter.readiness_frame then
        local watcher = CreateFrame("Frame", nil, UIParent)
        addon_data.hunter.readiness_frame = watcher
        watcher:RegisterEvent("PLAYER_STARTED_MOVING")
        watcher:RegisterEvent("PLAYER_STOPPED_MOVING")
        watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
        watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        watcher:SetScript("OnEvent", addon_data.hunter.OnReadinessEvent)
    end
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
    panel.show_gcd_spark_checkbox:SetChecked(settings.show_gcd_spark)
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
        
    panel.explaination:Hide()
    panel.explaination_text:Hide()
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
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "cooldown",
        addon_data.hunter.config_frame.cooldown_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.AutoShotCastColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "auto_cast",
        addon_data.hunter.config_frame.autoshot_cast_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.MultiClipColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "clip",
        addon_data.hunter.config_frame.multi_clip_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
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
    panel.title_text:SetTextColor(1, 0.82, 0, 1)
    
    -- General Settings Text
    panel.general_text = addon_data.config.TextFactory(panel, L["General Settings"], 16)
    panel.general_text:SetPoint("TOPLEFT", 10 , -50)
    panel.general_text:SetTextColor(1, 0.82, 0, 1)
    
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
        L["Changes the Auto Shot timer to a bar that fills from left to right"],
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
    panel.width_editbox:SetPoint("TOPLEFT", 260, -90, "BOTTOMRIGHT", 275, -115)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "HunterHeightEditBox",
        panel,
        L["Bar Height"],
        75,
        25,
        addon_data.hunter.HeightEditBoxOnEnter)
	panel.height_editbox:SetPoint("TOPLEFT", 340, -90, "BOTTOMRIGHT", 225, -115)
	-- Font Size EditBox
	panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        L["Font Size"],
        75,
        25,
        addon_data.hunter.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 180, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterXOffsetEditBox",
        panel,
        L["X Offset"],
        75,
        25,
        addon_data.hunter.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 220, -140, "BOTTOMRIGHT", 275, -165)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterYOffsetEditBox",
        panel,
        L["Y Offset"],
        75,
        25,
        addon_data.hunter.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 300, -140, "BOTTOMRIGHT", 225, -165)
    
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
    panel.autoshot_cast_color_picker:Show()
    
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "HunterInCombatAlphaSlider",
        panel,
        L["In Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 425, -90)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "HunterOOCAlphaSlider",
        panel,
        L["Out of Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 425, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "HunterBackplaneAlphaSlider",
        panel,
        L["Backplane Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 425, -190)
    
    -- Hunter Specific Settings Text
    panel.hunter_text = addon_data.config.TextFactory(panel, L["Hunter Specific Settings"], 16)
    panel.hunter_text:SetPoint("TOPLEFT", 10 , -230)
    panel.hunter_text:SetTextColor(1, 0.9, 0, 1)

    -- Show Multi-Shot Clip Bar Checkbox
    panel.show_multishot_clip_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowMultiShotClipBarCheckBox",
        panel,
        L["Multi-Shot clip bar"],
        L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."],
        addon_data.hunter.ShowMultiShotClipBarCheckBoxOnClick)
    panel.show_multishot_clip_bar_checkbox:SetPoint("TOPLEFT", 10, -230)
    panel.show_multishot_clip_bar_checkbox:Hide()
    
    -- Show Autoshot delay timer Checkbox
    panel.show_autoshot_delay_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowAutoShotDelayCheckBox",
        panel,
        L["Auto Shot delay timer"],
        L["Shows a timer that represents when Auto shot is delayed."],
        addon_data.hunter.ShowAutoShotDelayCheckBoxOnClick)
    panel.show_autoshot_delay_checkbox:SetPoint("TOPLEFT", 10, -250)
    
    -- Multi-shot clip color picker
    panel.multi_clip_color_picker = addon_data.config.color_picker_factory(
        'HunterMultiClipColorPicker',
        panel,
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a,
        L["Multi-Shot Clip Color"],
        addon_data.hunter.MultiClipColorPickerOnClick)
    panel.multi_clip_color_picker:SetPoint('TOPLEFT', 205, -255)
    panel.multi_clip_color_picker:Hide()
    
    -- Add the explaination text
    panel.explaination_text = addon_data.config.TextFactory(panel, L["Bar Explanation"], 16)
    panel.explaination_text:SetPoint("TOPLEFT", 80 , -560)
    panel.explaination_text:SetTextColor(1, 0.9, 0, 1)
    
    -- Add the explaination
    panel.explaination = panel:CreateTexture(nil, 'ARTWORK')
    panel.explaination:Hide()
    panel.explaination_text:Hide()
    
    -- Return the final panel
    addon_data.hunter.UpdateConfigPanelValues()
    return panel
end
