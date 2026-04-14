local frame = CreateFrame("Frame", "AbundanceBarFrame", UIParent, "BackdropTemplate")

-- Saved variables
AbundanceBarDB = AbundanceBarDB or {}
AbundanceBarDB.point = AbundanceBarDB.point or "CENTER"
AbundanceBarDB.relPoint = AbundanceBarDB.relPoint or "CENTER"
AbundanceBarDB.x = AbundanceBarDB.x or 0
AbundanceBarDB.y = AbundanceBarDB.y or -220
AbundanceBarDB.muteDundun = AbundanceBarDB.muteDundun or true

-- ====================== DUNDUN BLOCK BY NAME ======================
local dialogWasEnabled = nil
local permanentMuteTicker = nil

local function IsDundun(sender)
    if not sender then return false end
    local name = strlower(sender)
    return name:find("^dundun") or name:find("dundun$") or 
           name:find("dundun the") or name == "dundun"
end

local function RestoreDialogSetting()
    if dialogWasEnabled == nil then return end
    SetCVar("Sound_EnableDialog", dialogWasEnabled and "1" or "0")
    dialogWasEnabled = nil
end

local function ForceMuteOn()
    if dialogWasEnabled == nil then
        dialogWasEnabled = GetCVar("Sound_EnableDialog") == "1"
    end
    SetCVar("Sound_EnableDialog", "0")
end

local function StartPermanentMuteTicker()
    if permanentMuteTicker then return end
    permanentMuteTicker = C_Timer.NewTicker(0.3, function()
        if AbundanceBarDB.muteDundun then
            ForceMuteOn()
        else
            RestoreDialogSetting()
        end
    end)
end

local function StopPermanentMuteTicker()
    if permanentMuteTicker then
        permanentMuteTicker:Cancel()
        permanentMuteTicker = nil
    end
    RestoreDialogSetting()
end

local function HideTalkingHead()
    if TalkingHeadFrame then TalkingHeadFrame:Hide() end
end

local function SuppressTalkingHead()
    if not AbundanceBarDB.muteDundun then return end
    HideTalkingHead()
    C_Timer.After(0, HideTalkingHead)
    C_Timer.After(0.1, HideTalkingHead)
    C_Timer.After(0.3, HideTalkingHead)
end

-- Chat Filter
local function FilterChat(_, _, message, sender, ...)
    if IsDundun(sender) and AbundanceBarDB.muteDundun then
        ForceMuteOn()
        SuppressTalkingHead()
        return true
    end
    return false
end

-- ====================== MAIN FRAME ======================
frame:SetSize(400, 82)
frame:SetPoint(AbundanceBarDB.point, UIParent, AbundanceBarDB.relPoint, AbundanceBarDB.x, AbundanceBarDB.y)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.9)
frame:SetBackdropBorderColor(1, 0.82, 0, 1)
frame:Hide()

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(42, 42)
icon:SetPoint("LEFT", frame, "LEFT", 10, 4)

local statusBar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
statusBar:SetSize(300, 26)
statusBar:SetPoint("LEFT", icon, "RIGHT", 15, -3)
statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
statusBar:SetStatusBarColor(0.0, 0.65, 1.0)
statusBar:SetMinMaxValues(0, 1000)
statusBar:SetValue(0)

local bg = statusBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(statusBar)
bg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

statusBar:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
statusBar:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

local progressText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
progressText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
progressText:SetText("0 / 1000")

local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -8)
title:SetText("Blessing of Abundance")
title:SetTextColor(1, 0.82, 0)

local currencyFrame = CreateFrame("Frame", nil, frame)
currencyFrame:SetSize(300, 20)
currencyFrame:SetPoint("TOP", statusBar, "BOTTOM", 0, -4)

local currencyIcon = currencyFrame:CreateTexture(nil, "ARTWORK")
currencyIcon:SetSize(18, 18)
currencyIcon:SetPoint("LEFT", currencyFrame, "LEFT", 0, 0)

local currencyText = currencyFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
currencyText:SetPoint("LEFT", currencyIcon, "RIGHT", 6, 0)
currencyText:SetText("300 Unalloyed Abundance")

-- ====================== MUTE BUTTON (смещена ниже) ======================
local muteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
muteButton:SetSize(100, 24)
muteButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 5)   -- смещено на 3 пикселя ниже

local function UpdateMuteButton()
    muteButton:SetText(AbundanceBarDB.muteDundun and "Muted ON" or "Muted OFF")
end

muteButton:SetScript("OnClick", function()
    AbundanceBarDB.muteDundun = not AbundanceBarDB.muteDundun
    UpdateMuteButton()

    if AbundanceBarDB.muteDundun then
        ForceMuteOn()
        SuppressTalkingHead()
        StartPermanentMuteTicker()
        print("|cFF00FF00[AbundanceBar]|r Dundun blocked by name — ON")
    else
        StopPermanentMuteTicker()
        print("|cFFFFAA00[AbundanceBar]|r Dundun unblocked — OFF")
    end
end)

-- ====================== BAR LOGIC ======================
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

local function UpdateBar()
    if InCombatLockdown() then return end

    local spellID, iconTex, index = FindAura()
    if not spellID then
        frame:Hide()
        return
    end

    icon:SetTexture(iconTex or 134400)

    local tooltip = AbundanceTooltip or CreateFrame("GameTooltip", "AbundanceTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetUnitAura("player", index, "HARMFUL")

    local current = 0
    local maxVal = 1000
    local found = false

    for i = 1, tooltip:NumLines() do
        local txt = _G["AbundanceTooltipTextLeft" .. i] and _G["AbundanceTooltipTextLeft" .. i]:GetText()
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

    local displayMax = maxVal
    local currencyReward = 300
    if spellID == 1229266 then
        currencyReward = 300; displayMax = 1000
    elseif spellID == 1229501 then
        if current > 3000 then currencyReward = 900; displayMax = 5000
        else currencyReward = 600; displayMax = 3000 end
    elseif spellID == 1229681 then
        currencyReward = 900; displayMax = 1
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

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(CURRENCY_ID)
    currencyIcon:SetTexture(currencyInfo and currencyInfo.iconFileID or 134400)
    currencyText:SetText(currencyReward .. " Unalloyed Abundance")

    frame:Show()

    if AbundanceBarDB.muteDundun then
        ForceMuteOn()
        SuppressTalkingHead()
    end
end

-- Events, Filters, Dragging, Slash
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("TALKINGHEAD_REQUESTED")
frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
frame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")

frame:SetScript("OnEvent", function(_, event, unit, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        frame:ClearAllPoints()
        frame:SetPoint(AbundanceBarDB.point, UIParent, AbundanceBarDB.relPoint, AbundanceBarDB.x, AbundanceBarDB.y)
        C_Timer.After(0.5, UpdateBar)
        C_Timer.After(1, function()
            if AbundanceBarDB.muteDundun then StartPermanentMuteTicker() end
        end)

    elseif event == "PLAYER_REGEN_ENABLED" or event == "CURRENCY_DISPLAY_UPDATE" then
        C_Timer.After(0.2, UpdateBar)

    elseif event == "UNIT_AURA" and unit == "player" and not InCombatLockdown() then
        UpdateBar()

    elseif event == "TALKINGHEAD_REQUESTED" then
        SuppressTalkingHead()

    elseif (event == "CHAT_MSG_MONSTER_SAY" or event == "CHAT_MSG_MONSTER_YELL" or 
            event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_RAID_BOSS_EMOTE") then
        local message, sender = ...
        if IsDundun(sender) and AbundanceBarDB.muteDundun then
            ForceMuteOn()
            SuppressTalkingHead()
        end
    end
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", FilterChat)

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    AbundanceBarDB.point = p
    AbundanceBarDB.relPoint = rp
    AbundanceBarDB.x = x
    AbundanceBarDB.y = y
end)

SLASH_ABUNDANCE1 = "/abbar"
SlashCmdList["ABUNDANCE"] = function(msg)
    if msg == "reset" then
        AbundanceBarDB.x, AbundanceBarDB.y = 0, -220
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
        print("|cFF00FF00[AbundanceBar]|r Position reset.")
    else
        UpdateBar()
        print("|cFF00FF00[AbundanceBar]|r Bar updated.")
    end
end

-- Initialize
print("|cFF00FF00[AbundanceBar]|r Addon loaded (v3.0 Fixed)")
UpdateMuteButton()

C_Timer.After(2, function()
    if AbundanceBarDB.muteDundun then
        StartPermanentMuteTicker()
    end
end)