local E, L, V, P, G = unpack(ElvUI);
local EP = LibStub("LibElvUIPlugin-1.0");
local S = E:GetModule('Skins')
local AceGUI = LibStub("AceGUI-3.0") 
local ACR = LibStub("AceConfigRegistry-3.0")

-- 1. DEFINE NAMESPACE & MODULE
E.LootManager = E.LootManager or {}
local ELM = E:NewModule('LootManager', 'AceTimer-3.0', 'AceEvent-3.0');

-- ============================================================================
-- INTERNAL GRADIENT ENGINE (Replaces GradientLib)
-- ============================================================================
function ELM:Gradient(text, hexArray)
    if not text then return "" end
    if not hexArray or #hexArray == 0 then return text end
    if #hexArray == 1 then return "|cff" .. hexArray[1] .. text .. "|r" end
    
    local len = #text
    local numColors = #hexArray
    local result = ""
    
    local function hex2rgb(hex)
        return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
    end
    
    for i = 1, len do
        local char = text:sub(i, i)
        if char == " " then
            result = result .. char
        else
            local progress = (len > 1) and ((i - 1) / (len - 1)) or 0
            local scaled = progress * (numColors - 1)
            local index = math.floor(scaled) + 1
            if index >= numColors then index = numColors - 1 end
            
            local r1, g1, b1 = hex2rgb(hexArray[index])
            local r2, g2, b2 = hex2rgb(hexArray[index + 1])
            local p = scaled - (index - 1)
            
            local r = r1 + (r2 - r1) * p
            local g = g1 + (g2 - g1) * p
            local b = b1 + (b2 - b1) * p
            
            result = result .. string.format("|cff%02x%02x%02x%s|r", r, g, b, char)
        end
    end
    return result
end

-- 2. BRANDING PREFIX (Static Hex Gradient)
local BrandingPrefix = "|cff1784d1E|cff3399d1l|cff4daed1v|cff66c3d1U|cff80d8d1I|r |cff00CCFFLoo|cff5A8CEET|cffA335EEMana|cffD858C7ge|cffF06F85r|r"

-- 3. CONFIG TABLE CONTAINER
ELM.Config = {}

-- -------------------------------------------------------------------------
-- ROSTER CACHE
-- -------------------------------------------------------------------------
local RosterCache = {}
function ELM:UpdateRosterCache()
    wipe(RosterCache)
    local function CacheUnit(unit)
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            if class then RosterCache[name] = class end
        end
    end
    if UnitInRaid("player") then
        for i = 1, 40 do CacheUnit("raid"..i) end
    else
        for i = 1, 4 do CacheUnit("party"..i) end
        CacheUnit("player")
    end
end

-- -------------------------------------------------------------------------
-- TOOLTIP SCANNER
-- -------------------------------------------------------------------------
local ScanTooltip = CreateFrame("GameTooltip", "ELM_ScanTooltip", nil, "GameTooltipTemplate")
ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function IsItemBoP(slot)
    ScanTooltip:ClearLines()
    ScanTooltip:SetLootItem(slot)
    for i = 1, ScanTooltip:NumLines() do
        local line = _G["ELM_ScanTooltipTextLeft"..i]
        local text = line and line:GetText()
        if text and (text == ITEM_BIND_ON_PICKUP) then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------------------------
-- HELPERS
-- -------------------------------------------------------------------------
local function TruncateString(str, length)
    if not str then return "" end
    if string.len(str) > length then
        return string.sub(str, 1, length) .. "..."
    end
    return str
end

function ELM:Console(msg)
    local prefix = BrandingPrefix
    if not msg then return end
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. ": " .. tostring(msg))
end
ELM.Print = ELM.Console

function ELM:PrintAction(listName, action, itemLink)
    local listColor = "FF3333" 
    if string.find(listName, "BoE") then listColor = "FFD700" end
    
    local headerMsg = format("|cffffffff[|r%s|cffffffff]|r: |cff%s[%s]|r", BrandingPrefix, listColor, listName)
    DEFAULT_CHAT_FRAME:AddMessage(headerMsg)
    
    local bodyMsg = ""
    if itemLink then
        bodyMsg = format(" • %s |cffffffff%s|r", itemLink, action)
    else
        bodyMsg = format(" • |cffffffff%s|r", action)
    end
    DEFAULT_CHAT_FRAME:AddMessage(bodyMsg)
end

local function GetColoredName(name)
    if not name or name == "" then return name end
    local class = RosterCache[name]
    if not class then
        if UnitName("player") == name then
            _, class = UnitClass("player")
        end
    end
    if class then
        local color = RAID_CLASS_COLORS[class]
        if color then
            return format("|c%s%s|r", color.colorStr, name)
        end
    end
    return name
end

function ELM:PrintMasterLooterList()
    local db = E.LootManager.Global
	
	-- Define the colors here locally so the function can see them
    local AddonColors = {"1784d1", "00CCFF", "A335EE", "F06F85"}
    local BoEColors = {"FFD700", "FFFFFF", "FFD700"}
    
    -- Colored first letters and BoE Gradient
    local prefixGB  = "• |cff1eff00Green|r - |cff0070ddBlue|r"
    local prefixEp  = "• |cffa335eeEpic BoP|r"
    local prefixLeg = "• |cffff8000Legendary|r"
    local prefixBoE = "• " .. ELM:Gradient("Raid BoE", {"FFD700", "FFFFFF", "FFD700"})

    local function Resolve(val) return (val and val ~= "") and val or "None" end

    local nameGB  = Resolve(db.ml_greenblue)
    local nameEp  = Resolve(db.ml_epic_bop)
    local nameLeg = Resolve(db.ml_legendary)
    local nameBoE = Resolve(db.ml_epic_boe)

    -- Full gradient including the brackets and "Assignments"
-- Only the text is passed to the gradient; brackets are added as static white
local headerText = "|cffffffff[|r" .. ELM:Gradient("ElvUI Loot Manager Assignments", AddonColors) .. "|cffffffff]|r"

    DEFAULT_CHAT_FRAME:AddMessage(headerText)
    DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", prefixGB, GetColoredName(nameGB)))
    DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", prefixEp, GetColoredName(nameEp)))
    DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", prefixLeg, GetColoredName(nameLeg)))
    DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", prefixBoE, GetColoredName(nameBoE)))
end
-- -------------------------------------------------------------------------
-- WIDGETS
-- -------------------------------------------------------------------------
do
    local Type, Version = "ELM_ScrollSelect", 26
    local function OnAcquire(self)
        self:SetText(""); self:SetLabel(""); self:SetList({}); self:SetValue(nil)
        self.dropdown:Hide(); self.frame:SetHeight(50)
    end
    local function OnRelease(self)
        self.dropdown:Hide(); self.frame:ClearAllPoints(); self.frame:Hide()
    end
    local function SetList(self, list) self.list = list or {} end
    local function SetValue(self, value) self.value = value; self.text:SetText(self.list[value] or value or "") end
    local function GetValue(self) return self.value end
    
    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(50); frame:SetWidth(200)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local margin = 10
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, 0)
        label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        label:SetJustifyH("LEFT"); label:SetHeight(26)
        
        local btn = CreateFrame("Button", nil, frame)
        btn:SetHeight(22)
        btn:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        btn:SetPoint("RIGHT", frame, "RIGHT", -margin, 0)
        if btn.StripTextures then btn:StripTextures() end
        if btn.SetTemplate then btn:SetTemplate("Default", true) end
        
        btn:SetScript("OnEnter", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end end)
        btn:SetScript("OnLeave", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end end)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", btn, "LEFT", 0, 0)
        text:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
        text:SetJustifyH("LEFT"); text:SetWordWrap(false)
        btn.text = text
        
        local arrow = btn:CreateTexture(nil, "OVERLAY")
        arrow:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
        arrow:SetWidth(16); arrow:SetHeight(16)
        arrow:SetTexture(E.Media.Textures.ArrowUp) 
        arrow:SetRotation(3.14); arrow:SetVertexColor(1, 1, 1)

        local drop = CreateFrame("Frame", nil, UIParent)
        drop:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        drop:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
        drop:SetFrameStrata("TOOLTIP")
        if drop.SetTemplate then drop:SetTemplate("Default") end
        drop:Hide(); drop:EnableMouse(true)
        
        local scrollName = "ELM_ScrollSelect_Scroll" .. AceGUI:GetNextWidgetNum(Type)
        local scroll = CreateFrame("ScrollFrame", scrollName, drop, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", drop, "TOPLEFT", 6, -6)
        scroll:SetPoint("BOTTOMRIGHT", drop, "BOTTOMRIGHT", -26, 6)
        if S and S.HandleScrollBar then S:HandleScrollBar(_G[scrollName.."ScrollBar"]) end
        
        local content = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(content)
        content.obj = { Fire = function(_, event, val) frame.obj:Fire(event, val) end, dropdown = drop }

        local function RefreshDropdown()
            local children = { content:GetChildren() }
            for _, child in ipairs(children) do child:Hide() end
            local list = frame.obj.list or {}
            local keys = {}
            for k in pairs(list) do table.insert(keys, k) end
            table.sort(keys)
            local btnWidth = btn:GetWidth()
            drop:SetWidth(btnWidth)
            local numItems = #keys
            local showScroll = numItems > 10
            local contentWidth = showScroll and (btnWidth - 26) or (btnWidth - 12)
            if showScroll then
                if _G[scrollName.."ScrollBar"] then _G[scrollName.."ScrollBar"]:Show() end
                scroll:SetPoint("BOTTOMRIGHT", drop, "BOTTOMRIGHT", -26, 6)
            else
                if _G[scrollName.."ScrollBar"] then _G[scrollName.."ScrollBar"]:Hide() end
                scroll:SetPoint("BOTTOMRIGHT", drop, "BOTTOMRIGHT", -6, 6)
            end
            content:SetWidth(contentWidth)
            local y = 0
            for i, k in ipairs(keys) do
                local row = children[i]
                if not row then
                    row = CreateFrame("Button", nil, content)
                    row:SetHeight(20)
                    local t = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    t:SetPoint("LEFT", row, "LEFT", 0, 0)
                    t:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                    t:SetJustifyH("LEFT"); row.text = t
                    local hl = row:CreateTexture(nil, "BACKGROUND")
                    hl:SetAllPoints(); hl:SetTexture(E.Media.Textures.Highlight); hl:SetVertexColor(1,1,1,0.3); hl:SetBlendMode("ADD"); hl:Hide()
                    row.hl = hl
                    row:SetScript("OnClick", function(this) frame.obj:Fire("OnValueChanged", this.value); drop:Hide(); arrow:SetRotation(3.14); frame.obj:SetValue(this.value) end)
                    row:SetScript("OnEnter", function(this) this.text:SetTextColor(1,1,0); this.hl:Show() end)
                    row:SetScript("OnLeave", function(this) this.text:SetTextColor(1,1,1); this.hl:Hide() end)
                end
                row.value = k
                row.text:SetText(TruncateString(list[k], 100))
                row:SetWidth(contentWidth)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
                row:Show(); y = y + 20
            end
            if y == 0 then y = 20 end
            content:SetHeight(y)
            return y
        end

        btn:SetScript("OnClick", function()
            if drop:IsShown() then drop:Hide(); arrow:SetRotation(3.14)
            else local h = RefreshDropdown(); drop:SetHeight(math.min(math.max(h + 12, 40), 212)); drop:Show(); arrow:SetRotation(0) end
        end)
        
        local closer = CreateFrame("Button", nil, drop)
        closer:SetFrameStrata("FULLSCREEN_DIALOG"); closer:SetAllPoints(drop)
        closer:SetScript("OnClick", function() drop:Hide(); arrow:SetRotation(3.14) end)
        closer:SetScript("OnShow", function() closer:SetFrameLevel(drop:GetFrameLevel()-1) end) 

        local widget = { frame=frame, text=text, label=label, dropdown=drop, type=Type, SetText=function(s,t) s.text:SetText(t) end, SetLabel=function(s,t) s.label:SetText(t) end, SetList=SetList, SetValue=SetValue, GetValue=GetValue, OnAcquire=OnAcquire, OnRelease=OnRelease }
        frame.obj = widget
        return AceGUI:RegisterAsWidget(widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- WIDGET 2: ELM_Input
do
    local Type, Version = "ELM_Input", 22
    local function OnAcquire(self)
        self:SetText(""); self:SetLabel(""); self:SetDisabled(false); self.frame:SetHeight(50)
    end
    local function OnRelease(self) self.frame:ClearAllPoints(); self.frame:Hide() end
    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(50); frame:SetWidth(200)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local margin = 10 
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, 0); label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        label:SetJustifyH("LEFT"); label:SetHeight(26)
        local editbox = CreateFrame("EditBox", nil, frame)
        editbox:SetHeight(22); editbox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2); editbox:SetPoint("RIGHT", frame, "RIGHT", -margin, 0)
        editbox:SetFrameLevel(frame:GetFrameLevel() + 1); editbox:EnableMouse(true); editbox:SetAutoFocus(false)
        editbox:SetTextInsets(4,4,0,0); editbox:SetFontObject(ChatFontNormal); editbox:SetBlinkSpeed(0.5)
        if editbox.StripTextures then editbox:StripTextures() end
        if editbox.SetTemplate then editbox:SetTemplate("Default", true) end
        editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); if frame.obj.Fire then frame.obj:Fire("OnEnterPressed", self:GetText()) end end)
        editbox:SetScript("OnEditFocusGained", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end end)
        editbox:SetScript("OnEditFocusLost", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end end)
        local widget = { frame=frame, label=label, editbox=editbox, type=Type, OnAcquire=OnAcquire, OnRelease=OnRelease, SetText=function(s,t) editbox:SetText(t or "") end, SetLabel=function(self, text) label:SetText(text or ""); label:Show() end, SetDisabled=function(s,d) editbox:EnableMouse(not d); editbox:SetAlpha(d and 0.5 or 1) end }
        frame.obj = widget
        return AceGUI:RegisterAsWidget(widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- WIDGET 3: ELM_Input_Clean
do
    local Type, Version = "ELM_Input_Clean", 3
    local function OnAcquire(self)
        self:SetText(""); self:SetLabel(""); self:SetDisabled(false); self.frame:SetHeight(30)
    end
    local function OnRelease(self) self.frame:ClearAllPoints(); self.frame:Hide() end
    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(30); frame:SetWidth(200)
        local margin = 10 
        local editbox = CreateFrame("EditBox", nil, frame)
        editbox:SetHeight(22); editbox:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, -4); editbox:SetPoint("RIGHT", frame, "RIGHT", -margin, 0)
        editbox:SetFrameLevel(frame:GetFrameLevel() + 1); editbox:EnableMouse(true); editbox:SetAutoFocus(false)
        editbox:SetTextInsets(4,4,0,0); editbox:SetFontObject(ChatFontNormal); editbox:SetBlinkSpeed(0.5)
        if editbox.StripTextures then editbox:StripTextures() end
        if editbox.SetTemplate then editbox:SetTemplate("Default", true) end
        editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); if frame.obj.Fire then frame.obj:Fire("OnEnterPressed", self:GetText()) end end)
        editbox:SetScript("OnEditFocusGained", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end end)
        editbox:SetScript("OnEditFocusLost", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end end)
        local widget = { frame=frame, editbox=editbox, type=Type, OnAcquire=OnAcquire, OnRelease=OnRelease, SetText=function(s,t) editbox:SetText(t or "") end, SetLabel=function(self, text) end, SetDisabled=function(s,d) editbox:EnableMouse(not d); editbox:SetAlpha(d and 0.5 or 1) end }
        frame.obj = widget
        return AceGUI:RegisterAsWidget(widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- WIDGET 4: ELM_Button
do
    local Type, Version = "ELM_Button", 15
    local function OnAcquire(self) self:SetText(""); self:SetLabel(""); self:SetDisabled(false); self.frame:SetHeight(50)
    end
    local function OnRelease(self) self.frame:ClearAllPoints(); self.frame:Hide() end
    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(50); frame:SetWidth(200)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local margin = 10
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, 0); label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0); label:SetHeight(26)
        local btn = CreateFrame("Button", nil, frame)
        btn:SetHeight(22); btn:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2); btn:SetPoint("RIGHT", frame, "RIGHT", -margin, 0)
        if btn.StripTextures then btn:StripTextures() end
        if btn.SetTemplate then btn:SetTemplate("Default", true) end
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); text:SetPoint("CENTER"); btn.text = text
        btn:SetScript("OnClick", function(self) if frame.obj.Fire then frame.obj:Fire("OnClick") end end)
        btn:SetScript("OnEnter", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end end)
        btn:SetScript("OnLeave", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end end)
        local widget = { frame=frame, label=label, type=Type, OnAcquire=OnAcquire, OnRelease=OnRelease, SetText=function(s,t) btn.text:SetText(t or "") end, SetLabel=function(s,t) label:SetText(t or "") end, SetDisabled=function(s,d) if d then btn:Disable() else btn:Enable() end end }
        frame.obj = widget
        return AceGUI:RegisterAsWidget(widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- WIDGET 5: ELM_Button_Clean
do
    local Type, Version = "ELM_Button_Clean", 4
    local function OnAcquire(self) self:SetText(""); self:SetDisabled(false); self.frame:SetHeight(30)
    end
    local function OnRelease(self) self.frame:ClearAllPoints(); self.frame:Hide() end
    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(30); frame:SetWidth(200)
        local margin = 10
        local btn = CreateFrame("Button", nil, frame)
        btn:SetHeight(22); btn:SetPoint("LEFT", frame, "LEFT", margin, 0); btn:SetPoint("RIGHT", frame, "RIGHT", -margin, 0)
        if btn.StripTextures then btn:StripTextures() end
        if btn.SetTemplate then btn:SetTemplate("Default", true) end
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); text:SetPoint("CENTER"); btn.text = text
        btn:SetScript("OnClick", function(self) if frame.obj.Fire then frame.obj:Fire("OnClick") end end)
        btn:SetScript("OnEnter", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor)) end end)
        btn:SetScript("OnLeave", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(unpack(E.media.bordercolor)) end end)
        local widget = { frame=frame, type=Type, OnAcquire=OnAcquire, OnRelease=OnRelease, SetText=function(s,t) btn.text:SetText(t or "") end, SetLabel=function(s,t) end, SetDisabled=function(s,d) if d then btn:Disable() else btn:Enable() end end }
        frame.obj = widget
        return AceGUI:RegisterAsWidget(widget)
    end
    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- -------------------------------------------------------------------------
-- CORE INIT
-- -------------------------------------------------------------------------
local GlobalDefaults = {
    ['enabled'] = true,
    ['disablePopups'] = true,
    ['enableNeedList'] = true, 
    ['rollEpicBoE'] = true,  
    ['autoGreed'] = true, 
    ['autoDe'] = true,    
    ['hideBlizzardLootMessages'] = false,
    ['ml_greenblue'] = "",
    ['ml_epic_bop'] = "",
    ['ml_legendary'] = "",
    ['ml_epic_boe'] = "",
    ['needList'] = {}, 
    ['boeList'] = {},  
}

local function RunConfig()
    if not ELM.Config or #ELM.Config == 0 then return end
    for _, func in ipairs(ELM.Config) do func(ELM) end
end

function ELM:OnInitialize()
    if not ElvUI_LootManagerGlobal then ElvUI_LootManagerGlobal = {} end
    for k, v in pairs(GlobalDefaults) do
        if ElvUI_LootManagerGlobal[k] == nil then
            ElvUI_LootManagerGlobal[k] = v
        end
    end
    if type(ElvUI_LootManagerGlobal.needList) ~= "table" then ElvUI_LootManagerGlobal.needList = {} end
    if type(ElvUI_LootManagerGlobal.boeList) ~= "table" then ElvUI_LootManagerGlobal.boeList = {} end

    E.LootManager.Global = ElvUI_LootManagerGlobal
    EP:RegisterPlugin("ElvUI_LootManager", RunConfig)
end

-- State Variables
ELM.ActiveLootTimers = {} -- Map[SlotID] = timerHandle
ELM.StopLooting = false -- Global kill switch for current loot window interactions
ELM.IsMasterLooter = false
ELM.PendingAssignments = {} 

function ELM:UpdateMasterLooterState()
    local method, pid, rid = GetLootMethod()
    local isML = false
    if method == 'master' then
        if rid and rid > 0 then
            if UnitIsUnit("player", "raid"..rid) then isML = true end
        elseif pid and pid > 0 then -- Party
             if UnitIsUnit("player", "party"..pid) then isML = true end
        elseif pid == 0 then -- Player is leader/ML in party
             isML = true
        end
    end
    
    if isML and not ELM.IsMasterLooter then
        self:Console("Loot Manager Active (You are Master Looter).")
    end
    ELM.IsMasterLooter = isML
end

function ELM:CheckMasterLooter()
    self:UpdateMasterLooterState()
end

function ELM:OnEnable()
    -- REGISTER EVENTS
    self:RegisterEvent("START_LOOT_ROLL")
    self:RegisterEvent("LOOT_OPENED")
    self:RegisterEvent("LOOT_CLOSED")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckMasterLooter")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "CheckMasterLooter")
    self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", "CheckMasterLooter")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckMasterLooter")
    self:RegisterEvent("UI_ERROR_MESSAGE")
    
    -- CHAT FILTER
    local function LootMsgFilter(frame, event, message, ...)
        if E.LootManager.Global.enabled and E.LootManager.Global.hideBlizzardLootMessages then
            if ELM.IsMasterLooter then
                return true
            end
        end
        return false
    end

    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", LootMsgFilter)
    end
    
    -- Define Whitelist for Aggressive Handling
    local PopupWhitelist = {
        ["LOOT_BIND"] = true,
        ["CONFIRM_LOOT_ROLL"] = true,
        ["CONFIRM_DISENCHANT_ROLL"] = true,
    }

    -- HOOK SECURE FUNC FOR ONE BOX POPUP HANDLER
    hooksecurefunc("StaticPopup_Show", function(which, text_arg1, text_arg2, data)
        local dialog = nil
        for i = 1, 4 do
            local f = _G["StaticPopup"..i]
            if f and f:IsShown() and f.which == which then
                dialog = f
                break
            end
        end

        if not dialog then return end

        local db = E.LootManager.Global
        
        -- VISIBILITY RESET: Ensure all non-managed popups are visible immediately
        dialog:SetAlpha(1)

        -- Check if this specific popup type is in our handling whitelist
        if db.enabled and db.disablePopups and PopupWhitelist[which] then
            ELM:AutoConfirmPopup(which, dialog)
        end
    end)
    
    self:ScheduleTimer("CheckMasterLooter", 0.5)
    self:UpdateRosterCache()
end

-- ============================================================================
--  POPUP CONFIRMATION LOGIC
-- ============================================================================
function ELM:AutoConfirmPopup(which, dialog)
    dialog:SetAlpha(0)
    
    -- 1. LOOT BIND (Picking up BoP Items)
    if which == "LOOT_BIND" then
        local attempts = 0
        local function ConfirmBind()
            -- Safety check: Dialog must still match
            if not dialog:IsVisible() and dialog.which ~= which then return end
            
            local slot = dialog.data
            -- WAITING FOR DATA: Ensures slot is valid before Confirming
            if type(slot) == "number" then
                ConfirmLootSlot(slot)
                StaticPopup_Hide(which)
                
                -- Async Loot Pickup: Schedule LootSlot later to allow server processing
                if not ELM.StopLooting then
                    ELM:ScheduleTimer(function()
                        if not ELM.StopLooting and GetLootSlotInfo(slot) then
                            LootSlot(slot)
                        end
                    end, 0.25)
                end
            else
                attempts = attempts + 1
                if attempts > 20 then -- 1s Timeout
                    dialog:SetAlpha(1)
                    return
                end
                ELM:ScheduleTimer(ConfirmBind, 0.05)
            end
        end
        ConfirmBind()

    -- 2. LOOT ROLLS (Need/Greed/DE)
    elseif which == "CONFIRM_LOOT_ROLL" or which == "CONFIRM_DISENCHANT_ROLL" then
        
        local btn = _G[dialog:GetName().."Button1"]
        
        local function AttemptConfirm()
             if not dialog:IsVisible() and dialog.which ~= which then return end
             
             -- Unpack if table
             if type(dialog.data) == "table" then
                dialog.data2 = dialog.data[2]
                dialog.data = dialog.data[1]
             end
             
             -- Ensure data is ready (Numbers) before Clicking
             if (type(dialog.data) == "number") and (type(dialog.data2) == "number") then
                 if btn and btn:IsEnabled() then
                     btn:Click() -- Use Native Click for UI integrity (Fixes infinite timer)
                 else
                     -- Button not enabled yet? Wait.
                     ELM:ScheduleTimer(AttemptConfirm, 0.05)
                 end
             else
                 -- Data not ready? Wait.
                 ELM:ScheduleTimer(AttemptConfirm, 0.05)
             end
        end
        
        AttemptConfirm()
    end
end

function ELM:LOOT_CLOSED()
    -- Clear timers
    for slot, timer in pairs(ELM.ActiveLootTimers) do
        self:CancelTimer(timer)
    end
    wipe(ELM.ActiveLootTimers)
    ELM.StopLooting = false
end

function ELM:UI_ERROR_MESSAGE(event, msg)
    if not msg then return end
    local myName = UnitName("player")

    -- Smart check: If item is still being rolled for, STOP trying to auto-loot it.
    if strfind(msg, "rolled") or strfind(msg, "locked") then
        ELM.StopLooting = true
    end

    if strfind(msg, "Inventory is full") then
        local pending = ELM.PendingAssignments[myName]
        if pending then
            if pending.timer then self:CancelTimer(pending.timer) end
            self:Console(format("Your inventory is full. Cannot loot %s.", pending.link))
            ELM.PendingAssignments[myName] = nil
        end
        ELM.StopLooting = true
        return
    end
    
    if strfind(msg, "has too many") then
        for name, pending in pairs(ELM.PendingAssignments) do
            if strfind(msg, name) then
                if pending.timer then self:CancelTimer(pending.timer) end
                self:Console(format("%s already has this item %s", name, pending.link))
                ELM.PendingAssignments[name] = nil
                return
            end
        end
    end

    if strfind(msg, "carry any more") then
        local pending = ELM.PendingAssignments[myName]
        if pending then
            if pending.timer then self:CancelTimer(pending.timer) end
            self:Console(format("%s already has this item %s", myName, pending.link))
            ELM.PendingAssignments[myName] = nil
        end
    end
end

-- -------------------------------------------------------------------------
-- ROLL LOGIC (Auto Greed/Need/DE)
-- -------------------------------------------------------------------------
function ELM:START_LOOT_ROLL(event, id)
    local db = E.LootManager.Global
    if not db.enabled then return end

    local _, _, _, quality, bindOnPickUp, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(id)
    local link = GetLootRollItemLink(id)
    local itemID = link and tonumber(link:match("item:(%d+)"))
    
	-- Helper to clear the frame so it doesn't stay stuck at 0
local function DismissRollFrame(rollID)
    local attempts = 0
    local function Cleanup()
        local found = false
        for i = 1, NUM_GROUP_LOOT_FRAMES do
            local frame = _G["GroupLootFrame"..i]
            if frame and frame.rollID == rollID then
                -- 1. Stop all Blizzard and ElvUI timers
                frame:Hide()
                if frame.Timer then frame.Timer:Stop() end
                
                -- 2. Clear the ID so the frame is "freed" for the next item
                frame.rollID = nil
                found = true
            end
        end
        
        -- 3. If the frame was stubborn (still showing), try again 4 times (0.2 seconds total)
        attempts = attempts + 1
        if found and attempts < 4 then
            E:Delay(0.05, Cleanup)
        end
    end
    Cleanup()
end
	
-- 1. NEED LIST
if db.enableNeedList and itemID and db.needList[itemID] and canNeed then
    RollOnLoot(id, 1)
    self:Console("Auto Need: " .. (link or "Item"))
    E:Delay(0.1, function() DismissRollFrame(id) end) -- Safety delay
    return
end

-- 2. EPIC BOE
if db.rollEpicBoE and quality == 4 and not bindOnPickUp and canNeed then
    RollOnLoot(id, 1)
    self:Console("Auto Need (Epic BoE): " .. (link or "Item"))
    E:Delay(0.1, function() DismissRollFrame(id) end) -- Safety delay
    return
end

-- 3. GREEN/BLUE
if db.autoGreed and (quality == 2 or quality == 3) then
    if db.autoDe and canDisenchant then
        RollOnLoot(id, 3) -- Disenchant
    elseif canGreed then
        RollOnLoot(id, 2) -- Greed
    end
    
    -- Disenchanting often causes "ghost" bars; this delay clears them
    E:Delay(0.1, function() DismissRollFrame(id) end)
end
end

-- -------------------------------------------------------------------------
-- MASTER LOOT LOGIC
-- -------------------------------------------------------------------------
local function IsPlayerOnline(name)
    if not name then return false end
    if UnitName("player") == name then return true end
    
    if UnitInRaid("player") then
        for i=1, 40 do
            if UnitName("raid"..i) == name then
                return UnitIsConnected("raid"..i)
            end
        end
    else
        for i=1, 4 do
            if UnitName("party"..i) == name then
                return UnitIsConnected("party"..i)
            end
        end
    end
    return false
end

function ELM:LOOT_OPENED()
    ELM.StopLooting = false -- Reset loot safety flag on new window
    
    local db = E.LootManager.Global
    if not db.enabled then return end
    
    local method, partyid, raidid = GetLootMethod()
    if method ~= 'master' then return end

    local isMasterLooter = false
    if raidid and raidid > 0 then
        isMasterLooter = UnitIsUnit("player", "raid"..raidid)
    elseif partyid and partyid > 0 then
        isMasterLooter = UnitIsUnit("player", "party"..partyid)
    end
    if not isMasterLooter and GetLootMethod() == "master" and (GetNumRaidMembers() == 0) then
         local _, pid = GetLootMethod()
         if pid == 0 then isMasterLooter = true end
    end
    if not isMasterLooter then return end
    
    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    local candidateMap = {}
    local myName = UnitName("player")
    local myIndex = nil
    
    for i = 1, 40 do
        local cName = GetMasterLootCandidate(i)
        if not cName then break end
        candidateMap[string.lower(cName)] = i
        if cName == myName then myIndex = i end
    end

    local function GetAssignment(key, allowDefault)
        local input = db[key]
        if input and strtrim(input) ~= "" then
            local cleanInput = strtrim(input)
            local idx = candidateMap[string.lower(cleanInput)]
            if idx then 
                local candidateName = GetMasterLootCandidate(idx)
                if IsPlayerOnline(candidateName) then
                    return idx, candidateName 
                end
            end
        end
        if allowDefault then 
            return myIndex, myName 
        end
        return nil, nil
    end

    local idx_gb, name_gb = GetAssignment("ml_greenblue", true)
    local idx_ep_bop, name_ep_bop = GetAssignment("ml_epic_bop", true)
    local idx_leg, name_leg = GetAssignment("ml_legendary", false)
    local idx_boe, name_boe = GetAssignment("ml_epic_boe", true)
    
    local function GiveAndLog(slot, index, name, link)
        if not index then return end
        GiveMasterLoot(slot, index)
        local pending = { link = link, target = name }
        ELM:Console(format("Given %s to %s.", link, GetColoredName(name)))
        pending.timer = ELM:ScheduleTimer(function() 
             ELM.PendingAssignments[name] = nil 
        end, 1.0)
        ELM.PendingAssignments[name] = pending
    end

    for slot = numItems, 1, -1 do
        local link = GetLootSlotLink(slot)
        if link then
            local _, _, _, quality = GetLootSlotInfo(slot)
            local itemID = tonumber(link:match("item:(%d+)"))
            
            if itemID and db.boeList[itemID] then
                if idx_boe then GiveAndLog(slot, idx_boe, name_boe, link) end

            elseif quality == 5 then
                if idx_leg then 
                    GiveAndLog(slot, idx_leg, name_leg, link)
                else
                    local target = db.ml_legendary or "None"
                    self:Console(format("|cffff0000Loot candidate for legendary '%s' not found or misspelled.|r", target))
                end

            elseif quality == 4 then
                local isBoP = IsItemBoP(slot)
                if isBoP then
                    if idx_ep_bop then GiveAndLog(slot, idx_ep_bop, name_ep_bop, link) end
                else
                    if idx_boe then GiveAndLog(slot, idx_boe, name_boe, link) end
                end

            elseif quality == 2 or quality == 3 then
                if idx_gb then GiveMasterLoot(slot, idx_gb) end
            end
        end
    end
    CloseDropDownMenus()
end

function ELM:ToggleELMOptions()
    E:ToggleOptions("lootmanager")
end

E:RegisterChatCommand('elm', function()
    ELM:ToggleELMOptions()
end)