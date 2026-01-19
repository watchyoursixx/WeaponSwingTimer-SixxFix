local addon_name, addon_data = ...

local tooltip_name = addon_name .. "Tooltip"
local tooltip = CreateFrame("GameTooltip", tooltip_name, nil, "GameTooltipTemplate")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local font_string_base = tooltip_name .. "TextRight"
local speed_pattern = SPEED .. " (%d%.%d%d)"

local cache = {}

addon_data.GetRangedBaseSpeed = function()
	-- Default speed
	local speed = 1

	local weapon_id = GetInventoryItemID("player", INVSLOT_RANGED)
	if cache[weapon_id] then
		return cache[weapon_id]
	elseif not weapon_id then
		return speed
	end

	tooltip:ClearLines()
	tooltip:SetItemByID(weapon_id)
	for i = 1, tooltip:NumLines() do
		local fontString = _G[font_string_base .. i]
		local text = fontString:GetText()
		if text then
			local match = text:match(speed_pattern)
			if match then
				speed = match
				break
			end
		end
	end

	cache[weapon_id] = speed
	return speed
end
