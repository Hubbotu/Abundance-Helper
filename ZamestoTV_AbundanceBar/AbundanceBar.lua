local frame = CreateFrame("Frame", "AbundanceBarFrame", UIParent, "BackdropTemplate")

-- Saved variables
AbundanceBarDB = AbundanceBarDB or {}
AbundanceBarDB.point = AbundanceBarDB.point or "CENTER"
AbundanceBarDB.relPoint = AbundanceBarDB.relPoint or "CENTER"
AbundanceBarDB.x = AbundanceBarDB.x or 0
AbundanceBarDB.y = AbundanceBarDB.y or -220
AbundanceBarDB.muteDundun = AbundanceBarDB.muteDundun ~= false

-- ====================== LOCALIZATION (ADDED) ======================
local L = {}
local locale = GetLocale()

if locale == "ruRU" then
    L.currentPattern = "текущий взнос:%s*(%d*)%s*/%s*(%d+)"
    L.currentSearch  = "текущий взнос"
else
    L.currentPattern = "Current:%s*(%d*)%s*/%s*(%d+)"
    L.currentSearch  = "Current:"
end

-- ====================== DUNDUN BLOCK (FIXED) ======================
local restoreDialogAt = 0
local dialogWasEnabled = nil
local ticker = nil
local suppressTalkingHeadUntil = 0

local function NormalizeText(text)
    if type(text) ~= "string" then return "" end
    local s = strlower(text)
    s = gsub(s, "%s+", " ")
    return strmatch(s, "^%s*(.-)%s*$") or ""
end

local function IsDundun(sender)
    local name = NormalizeText(sender)
    return name:find("dundun", 1, true) ~= nil
end

local function StopDialogTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function RestoreDialogSetting()
    if dialogWasEnabled == nil then return end
    SetCVar("Sound_EnableDialog", dialogWasEnabled and "1" or "0")
    dialogWasEnabled = nil
    restoreDialogAt = 0
    StopDialogTicker()
end

local function EnsureDialogMutedFor(seconds)
    if not AbundanceBarDB.muteDundun then return end

    local now = GetTime()
    restoreDialogAt = math.max(restoreDialogAt, now + seconds)

    if dialogWasEnabled == nil then
        dialogWasEnabled = GetCVar("Sound_EnableDialog") == "1"
    end

    SetCVar("Sound_EnableDialog", "0")

    if ticker then return end

    ticker = C_Timer.NewTicker(0.2, function()
        if GetTime() >= restoreDialogAt then
            RestoreDialogSetting()
        end
    end)
end

local function HideTalkingHead()
    if TalkingHeadFrame then
        TalkingHeadFrame:Hide()
    end
end

local function EnsureTalkingHeadHiddenFor(seconds)
    if not AbundanceBarDB.muteDundun then return end

    suppressTalkingHeadUntil = math.max(suppressTalkingHeadUntil, GetTime() + seconds)

    HideTalkingHead()
    C_Timer.After(0, HideTalkingHead)
    C_Timer.After(0.1, HideTalkingHead)
    C_Timer.After(0.3, HideTalkingHead)
end

local function IsTalkingHeadSuppressed()
    return GetTime() < suppressTalkingHeadUntil
end

-- Chat Filter
local function FilterChat(_, _, message, sender, ...)
    if IsDundun(sender) and AbundanceBarDB.muteDundun then
        EnsureDialogMutedFor(4)
        EnsureTalkingHeadHiddenFor(4)
        return true
    end
    return false, message, sender, ...
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

-- ====================== BUTTON ======================
local muteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
muteButton:SetSize(100, 24)
muteButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 5)

local function UpdateMuteButton()
    muteButton:SetText(AbundanceBarDB.muteDundun and "Muted ON" or "Muted OFF")
end

muteButton:SetScript("OnClick", function()
    AbundanceBarDB.muteDundun = not AbundanceBarDB.muteDundun
    UpdateMuteButton()

    if not AbundanceBarDB.muteDundun then
        RestoreDialogSetting()
        print("|cFFFFAA00[AbundanceBar]|r Dundun unblocked — OFF")
    else
        print("|cFF00FF00[AbundanceBar]|r Dundun blocked — ON")
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

    if txt then
        -- ================= ENGLISH =================
        if txt:find("Current:") then
            local c, m = txt:match("Current:%s*(%d*)%s*/%s*(%d+)")
            if m then
                current = tonumber(c) or 0
                maxVal = tonumber(m) or 1000
                found = true
            end
            break
        end

        -- ================= RUSSIAN =================
        if txt:find("текущий взнос") or txt:find("Текущий взнос") then
            local c, m = txt:match("[Тт]екущий взнос:%s*(%d*)%s*/%s*(%d+)")
            if m then
                current = tonumber(c) or 0
                maxVal = tonumber(m) or 1000
                found = true
            end
            break
        end
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
end

-- ====================== EVENTS ======================
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
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(_, event, unit, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        frame:ClearAllPoints()
        frame:SetPoint(AbundanceBarDB.point, UIParent, AbundanceBarDB.relPoint, AbundanceBarDB.x, AbundanceBarDB.y)
        C_Timer.After(0.5, UpdateBar)

    elseif event == "PLAYER_REGEN_ENABLED" or event == "CURRENCY_DISPLAY_UPDATE" then
        C_Timer.After(0.2, UpdateBar)

    elseif event == "UNIT_AURA" and unit == "player" and not InCombatLockdown() then
        UpdateBar()

    elseif event == "TALKINGHEAD_REQUESTED" then
        if IsTalkingHeadSuppressed() then
            C_Timer.After(0, HideTalkingHead)
            C_Timer.After(0.1, HideTalkingHead)
            C_Timer.After(0.3, HideTalkingHead)
        end

    elseif (event == "CHAT_MSG_MONSTER_SAY" or event == "CHAT_MSG_MONSTER_YELL" or 
            event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_RAID_BOSS_EMOTE") then

        local message, sender = ...
        if IsDundun(sender) and AbundanceBarDB.muteDundun then
            EnsureDialogMutedFor(4)
            EnsureTalkingHeadHiddenFor(4)
        end

    elseif event == "PLAYER_LOGOUT" then
        RestoreDialogSetting()
    end
end)

-- Filters
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", FilterChat)

-- Drag
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    AbundanceBarDB.point = p
    AbundanceBarDB.relPoint = rp
    AbundanceBarDB.x = x
    AbundanceBarDB.y = y
end)

-- Slash
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

-- Init
print("|cFF00FF00[AbundanceBar]|r Addon loaded (v3.1 FIXED Dundun)")
UpdateMuteButton()