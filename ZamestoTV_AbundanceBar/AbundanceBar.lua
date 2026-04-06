local frame = CreateFrame("Frame", "AbundanceBarFrame", UIParent, "BackdropTemplate")

AbundanceBarDB = AbundanceBarDB or {}
AbundanceBarDB.point = AbundanceBarDB.point or "CENTER"
AbundanceBarDB.relPoint = AbundanceBarDB.relPoint or "CENTER"
AbundanceBarDB.x = AbundanceBarDB.x or 0
AbundanceBarDB.y = AbundanceBarDB.y or -220

-- Main frame
frame:SetSize(400, 82)
frame:SetPoint(AbundanceBarDB.point, UIParent, AbundanceBarDB.relPoint, AbundanceBarDB.x, AbundanceBarDB.y)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.9)
frame:SetBackdropBorderColor(1, 0.82, 0, 1)
frame:Hide()

-- Debuff icon
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(42, 42)
icon:SetPoint("LEFT", frame, "LEFT", 10, 4)

-- Progress bar
local statusBar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
statusBar:SetSize(300, 26)
statusBar:SetPoint("LEFT", icon, "RIGHT", 15, -3)
statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
statusBar:SetStatusBarColor(0.0, 0.65, 1.0)
statusBar:SetMinMaxValues(0, 1000)
statusBar:SetValue(0)
statusBar:Show()

local bg = statusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(statusBar)
bg:SetColorTexture(0.05, 0.05, 0.05, 0.85)
bg:Show()

statusBar:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
statusBar:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

-- Progress text
local progressText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
progressText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
progressText:SetText("0 / 1000")

-- Title
local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -8)
title:SetText("Blessing of Abundance")
title:SetTextColor(1, 0.82, 0)

-- Currency line
local currencyFrame = CreateFrame("Frame", nil, frame)
currencyFrame:SetSize(300, 20)
currencyFrame:SetPoint("TOP", statusBar, "BOTTOM", 0, -4)

local currencyIcon = currencyFrame:CreateTexture(nil, "ARTWORK")
currencyIcon:SetSize(18, 18)
currencyIcon:SetPoint("LEFT", currencyFrame, "LEFT", 0, 0)

local currencyText = currencyFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
currencyText:SetPoint("LEFT", currencyIcon, "RIGHT", 6, 0)
currencyText:SetText("300 Unalloyed Abundance")

-- Tooltip
local tooltip = CreateFrame("GameTooltip", "AbundanceTooltip", nil, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

local targetIDs = {1229266, 1229501, 1229681}
local CURRENCY_ID = 3377

local function IsTargetAura(aura)
    if not aura or not aura.spellId then return false end
    for _, id in ipairs(targetIDs) do
        if aura.spellId == id then return true end
    end
    return false
end

local function FindAura()
    for i = 1, 100 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
        if aura and IsTargetAura(aura) then
            return aura.spellId, aura.icon, i
        end
    end
    return nil
end

local function GetCurrencyAmount()
    local info = C_CurrencyInfo.GetCurrencyInfo(CURRENCY_ID)
    return info and info.quantity or 0
end

local function UpdateBar()
    if InCombatLockdown() then return end

    local spellID, iconTex, index = FindAura()
    if not spellID then
        frame:Hide()
        return
    end

    icon:SetTexture(iconTex or 134400)

    tooltip:ClearLines()
    tooltip:SetUnitAura("player", index, "HARMFUL")

    local current = 0
    local maxVal = 1000
    local found = false

    for i = 1, tooltip:NumLines() do
        local txt = _G["AbundanceTooltipTextLeft"..i] and _G["AbundanceTooltipTextLeft"..i]:GetText()
        if txt and txt:find("Current:") then
            local c, m = txt:match("Current:%s*(%d*)%s*/%s*(%d+)")
            if m then
                current = tonumber(c) or 0
                maxVal = tonumber(m) or 1000
                found = true
            end
            break
        end
    end

    -- Progress bar + currency logic
    local displayMax = maxVal
    local currencyReward = 300

    if spellID == 1229266 then
        currencyReward = 300
        displayMax = 1000
    elseif spellID == 1229501 then
        if current > 3000 then
            currencyReward = 900
            displayMax = 5000
        else
            currencyReward = 600
            displayMax = 3000
        end
    elseif spellID == 1229681 then
        currencyReward = 900
        displayMax = 1
    end

    if found then
        statusBar:SetMinMaxValues(0, displayMax)
        statusBar:SetValue(current)
        progressText:SetText(current .. " / " .. displayMax)
        statusBar:SetStatusBarColor(0.0, 0.65, 1.0)

        if current >= displayMax * 0.98 then
            progressText:SetTextColor(0, 1, 0)
        else
            progressText:SetTextColor(1, 1, 1)
        end
    elseif spellID == 1229681 then
        statusBar:SetMinMaxValues(0, 1)
        statusBar:SetValue(1)
        progressText:SetText("FINAL TIER — MAXED")
        statusBar:SetStatusBarColor(0, 1, 0)
    end

    -- Currency display
    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(CURRENCY_ID)
    local currencyIconTexture = currencyInfo and currencyInfo.iconFileID or 134400

    currencyIcon:SetTexture(currencyIconTexture)
    currencyText:SetText(currencyReward .. "   Unalloyed Abundance")

    frame:Show()
    statusBar:Show()
    bg:Show()
end

-- Events
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        frame:ClearAllPoints()
        frame:SetPoint(AbundanceBarDB.point, UIParent, AbundanceBarDB.relPoint, AbundanceBarDB.x, AbundanceBarDB.y)
        C_Timer.After(0.5, UpdateBar)
    elseif event == "PLAYER_REGEN_ENABLED" or event == "CURRENCY_DISPLAY_UPDATE" then
        C_Timer.After(0.2, UpdateBar)
    elseif event == "UNIT_AURA" and unit == "player" and not InCombatLockdown() then
        UpdateBar()
    end
end)

-- Dragging
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    AbundanceBarDB.point = p
    AbundanceBarDB.relPoint = rp
    AbundanceBarDB.x = x
    AbundanceBarDB.y = y
end)

-- Slash command
SLASH_ABUNDANCE1 = "/abbar"
SlashCmdList["ABUNDANCE"] = function(msg)
    if msg == "reset" then
        AbundanceBarDB.x, AbundanceBarDB.y = 0, -220
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
        print("|cFF00FF00[AbundanceBar]|r Position reset.")
    else
        if InCombatLockdown() then
            print("|cFFFF0000[AbundanceBar]|r Cannot update during combat.")
        else
            UpdateBar()
            print("|cFF00FF00[AbundanceBar]|r Bar updated.")
        end
    end
end

print("|cFF00FF00[AbundanceBar]|r Addon loaded (v2.1 — All texts in English)")